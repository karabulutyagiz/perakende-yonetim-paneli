from decimal import Decimal

import pytest

from app.models import Product
from app.services import user_service


@pytest.mark.asyncio
async def test_platform_owner_can_create_market_linked_to_wholesaler_and_scope_products(
    app_client, db, tenant, tenant_b, user, user_b
):
    platform_owner = await user_service.create_platform_owner(
        db,
        "platform@example.com",
        "Platform Admin",
        "StrongPass123!",
    )

    product_a = Product(
        tenant_id=tenant.id,
        name="Toptanci A Urunu",
        unit="adet",
        price=Decimal("15.00"),
        stock=Decimal("50.000"),
    )
    product_b = Product(
        tenant_id=tenant_b.id,
        name="Toptanci B Urunu",
        unit="adet",
        price=Decimal("20.00"),
        stock=Decimal("30.000"),
    )
    db.add_all([product_a, product_b])
    await db.commit()

    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": platform_owner.email, "password": "StrongPass123!"},
    )
    assert login.status_code == 200, login.text
    platform_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    created = await app_client.post(
        "/api/v1/sudo/markets",
        headers=platform_headers,
        json={
            "market_name": "Cinar Market",
            "wholesaler_tenant_id": str(tenant.id),
            "owner_email": "market@example.com",
            "owner_full_name": "Market Yetkilisi",
            "contact_phone": "05551112233",
        },
    )
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["market_name"] == "Cinar Market"
    assert body["wholesaler_tenant_id"] == str(tenant.id)
    assert body["wholesaler_name"] == tenant.name

    market_login = await app_client.post(
        "/api/v1/auth/login",
        json={
            "email": "market@example.com",
            "password": body["generated_password"],
        },
    )
    assert market_login.status_code == 200, market_login.text
    market_headers = {"Authorization": f"Bearer {market_login.json()['access_token']}"}

    products = await app_client.get("/api/v1/products", headers=market_headers)
    assert products.status_code == 200, products.text
    names = [row["name"] for row in products.json()]
    assert names == ["Toptanci A Urunu"]
