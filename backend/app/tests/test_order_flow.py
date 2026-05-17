from decimal import Decimal

import pytest

from app.models import Customer, Product
from app.services import user_service


async def _seed_customer_account(db, user):
    customer = Customer(
        tenant_id=user.tenant_id,
        name="Musteri 1",
        phone="05550000000",
    )
    product = Product(
        tenant_id=user.tenant_id,
        name="Un 10kg",
        unit="adet",
        price=Decimal("50.00"),
        stock=Decimal("12.000"),
    )
    db.add_all([customer, product])
    await db.flush()
    customer_user = await user_service.create_customer_user(
        db,
        tenant_id=user.tenant_id,
        customer=customer,
        email="musteri@example.com",
        password="StrongPass123!",
    )
    await db.commit()
    await db.refresh(customer)
    await db.refresh(product)
    await db.refresh(customer_user)
    return customer, product, customer_user


@pytest.mark.asyncio
async def test_customer_can_create_order(app_client, db, user):
    customer, product, _ = await _seed_customer_account(db, user)
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "musteri@example.com", "password": "StrongPass123!"},
    )
    assert login.status_code == 200, login.text
    access = login.json()["access_token"]

    resp = await app_client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "note": "Kapıya bırak",
            "items": [{"product_id": str(product.id), "quantity": "2"}],
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["customer_id"] == str(customer.id)
    assert body["status"] == "pending"
    assert float(body["total"]) == 100.0


@pytest.mark.asyncio
async def test_convert_order_to_invoice_reduces_stock(app_client, auth_client, db, user):
    customer, product, _ = await _seed_customer_account(db, user)
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "musteri@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    created = await app_client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "items": [{"product_id": str(product.id), "quantity": "3"}],
        },
    )
    assert created.status_code == 201, created.text
    order_id = created.json()["id"]

    converted = await app_client.post(
        f"/api/v1/orders/{order_id}/convert-to-invoice",
        headers=auth_client.headers,
        json={"payment_method": "nakit"},
    )
    assert converted.status_code == 200, converted.text
    body = converted.json()
    assert body["status"] == "converted"
    assert body["invoice_id"] is not None

    await db.refresh(product)
    assert product.stock == Decimal("9.000")


@pytest.mark.asyncio
async def test_convert_order_to_invoice_with_partial_payment_creates_debt(
    app_client, auth_client, db, user
):
    customer, product, _ = await _seed_customer_account(db, user)
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "musteri@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    created = await app_client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "items": [{"product_id": str(product.id), "quantity": "2"}],
        },
    )
    order_id = created.json()["id"]

    converted = await app_client.post(
        f"/api/v1/orders/{order_id}/convert-to-invoice",
        headers=auth_client.headers,
        json={
            "payment_method": "borc",
            "cash_amount": "40",
            "card_amount": "10",
            "debt_amount": "50",
        },
    )
    assert converted.status_code == 200, converted.text

    debts = await auth_client.get(
        "/api/v1/debts", params={"customer_id": str(customer.id)}
    )
    assert debts.status_code == 200, debts.text
    rows = debts.json()
    assert len(rows) == 1
    assert float(rows[0]["total_amount"]) == 100.0
    assert float(rows[0]["paid_amount"]) == 50.0


@pytest.mark.asyncio
async def test_convert_order_to_invoice_rejects_payment_above_order_total(
    app_client, auth_client, db, user
):
    customer, product, _ = await _seed_customer_account(db, user)
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "musteri@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    created = await app_client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "items": [{"product_id": str(product.id), "quantity": "2"}],
        },
    )
    assert created.status_code == 201, created.text
    order_id = created.json()["id"]

    converted = await app_client.post(
        f"/api/v1/orders/{order_id}/convert-to-invoice",
        headers=auth_client.headers,
        json={
            "payment_method": "borc",
            "cash_amount": "60",
            "card_amount": "30",
            "debt_amount": "20",
        },
    )
    assert converted.status_code == 400, converted.text
    assert converted.json()["detail"] == "Odeme toplami siparis tutarindan fazla olamaz"


@pytest.mark.asyncio
async def test_invoice_response_uses_real_order_number(app_client, auth_client, db, user):
    customer, product, _ = await _seed_customer_account(db, user)
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "musteri@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    created = await app_client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "items": [{"product_id": str(product.id), "quantity": "2"}],
        },
    )
    assert created.status_code == 201, created.text
    order_body = created.json()
    order_id = order_body["id"]
    order_number = order_body["order_number"]

    converted = await app_client.post(
        f"/api/v1/orders/{order_id}/convert-to-invoice",
        headers=auth_client.headers,
        json={"payment_method": "nakit"},
    )
    assert converted.status_code == 200, converted.text
    invoice_id = converted.json()["invoice_id"]

    invoice = await auth_client.get(f"/api/v1/invoices/{invoice_id}")
    assert invoice.status_code == 200, invoice.text
    assert invoice.json()["order_number"] == order_number

    invoices = await auth_client.get("/api/v1/invoices")
    assert invoices.status_code == 200, invoices.text
    assert any(
        row["id"] == invoice_id and row["order_number"] == order_number
        for row in invoices.json()
    )
