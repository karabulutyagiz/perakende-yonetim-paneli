"""Fatura oluşturma + stok düşürme + borç otomatik açılması."""
from decimal import Decimal

import pytest

from app.models import Customer, Product


async def _seed(db, tenant, *, stock: Decimal = Decimal("10")) -> tuple[Customer, Product]:
    customer = Customer(name="Ali Amca", phone="05551112233", tenant_id=tenant.id)
    product = Product(
        name="Ayçiçek Yağı 5L",
        unit="adet",
        price=Decimal("120.00"),
        stock=stock,
        tenant_id=tenant.id,
    )
    db.add_all([customer, product])
    await db.commit()
    await db.refresh(customer)
    await db.refresh(product)
    return customer, product


@pytest.mark.asyncio
async def test_cash_invoice_reduces_stock(auth_client, db, tenant):
    customer, product = await _seed(db, tenant, stock=Decimal("10"))
    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": str(product.id), "quantity": "3"}],
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert float(body["total"]) == 360.0
    assert len(body["items"]) == 1

    await db.refresh(product)
    assert product.stock == Decimal("7.000")


@pytest.mark.asyncio
async def test_debt_invoice_creates_debt(auth_client, db, tenant):
    customer, product = await _seed(db, tenant)
    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "borc",
            "items": [{"product_id": str(product.id), "quantity": "2"}],
        },
    )
    assert resp.status_code == 201

    debts = await auth_client.get(
        "/api/v1/debts", params={"customer_id": str(customer.id)}
    )
    assert debts.status_code == 200
    rows = debts.json()
    assert len(rows) == 1
    assert float(rows[0]["total_amount"]) == 240.0
    assert rows[0]["status"] in {"yesil", "sari", "kirmizi"}


@pytest.mark.asyncio
async def test_insufficient_stock_rejected(auth_client, db, tenant):
    customer, product = await _seed(db, tenant, stock=Decimal("1"))
    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": str(product.id), "quantity": "5"}],
        },
    )
    assert resp.status_code == 400
    await db.refresh(product)
    assert product.stock == Decimal("1.000")  # rollback kanıtı


@pytest.mark.asyncio
async def test_empty_cart_rejected(auth_client, db, tenant):
    customer, _ = await _seed(db, tenant)
    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "nakit",
            "items": [],
        },
    )
    # Pydantic min_length=1 → 422
    assert resp.status_code == 422
