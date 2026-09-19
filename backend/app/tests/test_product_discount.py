"""Ürün kartındaki indirim (yüzde / TL) — doğrulama ve satışa yansıması."""
from decimal import Decimal

import pytest

from app.models import Customer
from app.models.product import DiscountType, compute_effective_price


def test_compute_effective_price_rules():
    # İndirim yoksa liste fiyatı aynen kalır.
    assert compute_effective_price(Decimal("120"), None, Decimal("0")) == Decimal("120.00")
    # Yüzde indirim
    assert compute_effective_price(
        Decimal("120"), DiscountType.PERCENT, Decimal("25")
    ) == Decimal("90.00")
    # TL indirim
    assert compute_effective_price(
        Decimal("120"), DiscountType.AMOUNT, Decimal("20")
    ) == Decimal("100.00")
    # Fiyattan büyük TL indirimi fiyatı sıfıra çeker, negatife düşmez.
    assert compute_effective_price(
        Decimal("50"), DiscountType.AMOUNT, Decimal("80")
    ) == Decimal("0.00")
    # Kuruş yuvarlama
    assert compute_effective_price(
        Decimal("9.99"), DiscountType.PERCENT, Decimal("10")
    ) == Decimal("8.99")


async def _create_product(client, **overrides) -> dict:
    payload = {
        "name": "Ayçiçek Yağı 5L",
        "unit": "adet",
        "price": "120.00",
        "stock": "10",
    }
    payload.update(overrides)
    resp = await client.post("/api/v1/products", json=payload)
    return resp


@pytest.mark.asyncio
async def test_create_product_with_percent_discount(auth_client):
    resp = await _create_product(
        auth_client, discount_type="percent", discount_value="25"
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["discount_type"] == "percent"
    assert float(body["discount_value"]) == 25.0
    assert float(body["effective_price"]) == 90.0


@pytest.mark.asyncio
async def test_create_product_with_amount_discount(auth_client):
    resp = await _create_product(
        auth_client, discount_type="amount", discount_value="20"
    )
    assert resp.status_code == 201, resp.text
    assert float(resp.json()["effective_price"]) == 100.0


@pytest.mark.asyncio
async def test_product_without_discount_has_list_effective_price(auth_client):
    resp = await _create_product(auth_client)
    assert resp.status_code == 201
    body = resp.json()
    assert body["discount_type"] is None
    assert float(body["effective_price"]) == 120.0


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "discount_type,value",
    [
        ("percent", "150"),  # yüzde 100'den büyük
        ("amount", "500"),   # TL indirimi fiyattan büyük
        ("percent", "0"),    # sıfır indirim anlamsız
    ],
)
async def test_invalid_discount_rejected(auth_client, discount_type, value):
    resp = await _create_product(
        auth_client, discount_type=discount_type, discount_value=value
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_update_can_clear_discount(auth_client):
    created = await _create_product(
        auth_client, discount_type="percent", discount_value="25"
    )
    product_id = created.json()["id"]

    resp = await auth_client.put(
        f"/api/v1/products/{product_id}",
        json={"discount_type": None, "discount_value": 0},
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["discount_type"] is None
    assert float(body["discount_value"]) == 0.0
    assert float(body["effective_price"]) == 120.0


@pytest.mark.asyncio
async def test_update_rejects_amount_discount_above_new_price(auth_client):
    created = await _create_product(
        auth_client, discount_type="amount", discount_value="20"
    )
    product_id = created.json()["id"]

    # Fiyat indirimin altına çekilirse tanım geçersiz olur.
    resp = await auth_client.put(
        f"/api/v1/products/{product_id}",
        json={"price": "10.00"},
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_invoice_applies_product_discount(auth_client, db, tenant):
    customer = Customer(name="Ali Amca", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)

    created = await _create_product(
        auth_client, discount_type="percent", discount_value="25"
    )
    product_id = created.json()["id"]

    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": product_id, "quantity": "2"}],
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()

    # 2 × 90 = 180 tahsil edilir; liste fiyatı 2 × 120 = 240.
    assert float(body["total"]) == 180.0
    assert float(body["subtotal"]) == 240.0
    assert float(body["discount_total"]) == 60.0

    item = body["items"][0]
    assert float(item["unit_price"]) == 90.0
    assert float(item["list_unit_price"]) == 120.0
    assert float(item["discount_total"]) == 60.0


@pytest.mark.asyncio
async def test_invoice_without_discount_has_zero_discount_total(auth_client, db, tenant):
    customer = Customer(name="Veli Amca", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)

    created = await _create_product(auth_client)
    product_id = created.json()["id"]

    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": product_id, "quantity": "2"}],
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert float(body["total"]) == 240.0
    assert float(body["discount_total"]) == 0.0
    assert body["items"][0]["list_unit_price"] is None


@pytest.mark.asyncio
async def test_debt_invoice_uses_discounted_total(auth_client, db, tenant):
    """İndirim borç tutarına da yansımalı — aksi halde müşteri fazla borçlanır."""
    customer = Customer(name="Borçlu Müşteri", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)

    created = await _create_product(
        auth_client, discount_type="amount", discount_value="20"
    )
    product_id = created.json()["id"]

    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(customer.id),
            "payment_method": "borc",
            "items": [{"product_id": product_id, "quantity": "3"}],
        },
    )
    assert resp.status_code == 201, resp.text

    debts = await auth_client.get(
        "/api/v1/debts", params={"customer_id": str(customer.id)}
    )
    # 3 × (120 - 20) = 300
    assert float(debts.json()[0]["total_amount"]) == 300.0
