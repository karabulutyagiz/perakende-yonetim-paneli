"""Cross-tenant veri izolasyonu — bir işletme başka işletmenin verisini göremez,
referans veremez, silemez."""
from datetime import date, timedelta
from decimal import Decimal

import pytest

from app.models import Customer, Debt, DebtStatus, Invoice, PaymentMethod, Product

# auth_client → tenant A (admin@example.com)
# auth_client_b → tenant B (other@example.com)


@pytest.mark.asyncio
async def test_list_endpoints_only_return_own_tenant_data(
    auth_client, auth_client_b, db, tenant, tenant_b
):
    """Her tenant'ın list endpoint'i sadece kendi datasını döner."""
    a_customer = Customer(name="Müşteri A", tenant_id=tenant.id)
    b_customer = Customer(name="Müşteri B", tenant_id=tenant_b.id)
    a_product = Product(
        name="Ürün A", unit="adet", price=Decimal("10"), stock=Decimal("5"), tenant_id=tenant.id
    )
    b_product = Product(
        name="Ürün B", unit="adet", price=Decimal("20"), stock=Decimal("5"), tenant_id=tenant_b.id
    )
    db.add_all([a_customer, b_customer, a_product, b_product])
    await db.commit()

    # Tenant A sadece kendi müşterisini görmeli
    a_customers = (await auth_client.get("/api/v1/customers")).json()
    assert {c["name"] for c in a_customers} == {"Müşteri A"}

    a_products = (await auth_client.get("/api/v1/products")).json()
    assert {p["name"] for p in a_products} == {"Ürün A"}

    # Tenant B sadece kendi müşterisini görmeli
    b_customers = (await auth_client_b.get("/api/v1/customers")).json()
    assert {c["name"] for c in b_customers} == {"Müşteri B"}

    b_products = (await auth_client_b.get("/api/v1/products")).json()
    assert {p["name"] for p in b_products} == {"Ürün B"}


@pytest.mark.asyncio
async def test_cannot_get_other_tenant_resource_by_id(
    auth_client, auth_client_b, db, tenant_b
):
    """Tenant A, Tenant B'nin müşteri/ürün/fatura ID'sini bilse bile 404 alır."""
    b_customer = Customer(name="Gizli Müşteri", tenant_id=tenant_b.id)
    b_product = Product(
        name="Gizli Ürün",
        unit="adet",
        price=Decimal("99"),
        stock=Decimal("3"),
        tenant_id=tenant_b.id,
    )
    db.add_all([b_customer, b_product])
    await db.commit()
    await db.refresh(b_customer)
    await db.refresh(b_product)

    # Tenant A, Tenant B'nin kaynaklarına erişmeye çalışır
    assert (await auth_client.get(f"/api/v1/customers/{b_customer.id}")).status_code == 404
    assert (await auth_client.get(f"/api/v1/products/{b_product.id}")).status_code == 404


@pytest.mark.asyncio
async def test_cannot_update_or_delete_other_tenant_resource(
    auth_client, db, tenant_b
):
    """Tenant A, Tenant B'nin müşterisini güncellemeyi veya silmeyi denerse 404."""
    b_customer = Customer(name="Korunan Müşteri", tenant_id=tenant_b.id)
    db.add(b_customer)
    await db.commit()
    await db.refresh(b_customer)

    # Update denemesi
    upd = await auth_client.put(
        f"/api/v1/customers/{b_customer.id}",
        json={"name": "Hacked Name"},
    )
    assert upd.status_code == 404

    # Delete denemesi
    dele = await auth_client.delete(f"/api/v1/customers/{b_customer.id}")
    assert dele.status_code == 404

    # Müşteri hala olduğu gibi mi?
    await db.refresh(b_customer)
    assert b_customer.name == "Korunan Müşteri"


@pytest.mark.asyncio
async def test_cannot_create_invoice_for_other_tenant_customer(
    auth_client, db, tenant, tenant_b
):
    """Tenant A, kendi ürünüyle Tenant B'nin müşterisine fatura kesemez."""
    a_product = Product(
        name="A Ürünü", unit="adet", price=Decimal("50"), stock=Decimal("10"), tenant_id=tenant.id
    )
    b_customer = Customer(name="B Müşterisi", tenant_id=tenant_b.id)
    db.add_all([a_product, b_customer])
    await db.commit()
    await db.refresh(a_product)
    await db.refresh(b_customer)

    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(b_customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": str(a_product.id), "quantity": "1"}],
        },
    )
    # Müşteri farklı tenant'ta → 404
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_cannot_use_other_tenant_product_in_invoice(
    auth_client, db, tenant, tenant_b
):
    """Tenant A, Tenant B'nin ürün ID'siyle fatura kesemez."""
    a_customer = Customer(name="A Müşterisi", tenant_id=tenant.id)
    b_product = Product(
        name="B Ürünü", unit="adet", price=Decimal("50"), stock=Decimal("10"), tenant_id=tenant_b.id
    )
    db.add_all([a_customer, b_product])
    await db.commit()
    await db.refresh(a_customer)
    await db.refresh(b_product)

    resp = await auth_client.post(
        "/api/v1/invoices",
        json={
            "customer_id": str(a_customer.id),
            "payment_method": "nakit",
            "items": [{"product_id": str(b_product.id), "quantity": "1"}],
        },
    )
    # Ürün farklı tenant'ta → 404 (invoice_service products dict'te bulamaz)
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_debts_are_tenant_scoped(
    auth_client, auth_client_b, db, tenant, tenant_b
):
    """Borç listesi ve özet, sadece kendi tenant'ın borçlarını içerir."""
    today = date.today()
    a_customer = Customer(name="Borçlu A", tenant_id=tenant.id)
    b_customer = Customer(name="Borçlu B", tenant_id=tenant_b.id)
    db.add_all([a_customer, b_customer])
    await db.commit()
    await db.refresh(a_customer)
    await db.refresh(b_customer)

    # A için borç
    a_inv = Invoice(
        tenant_id=tenant.id,
        customer_id=a_customer.id,
        total=Decimal("100"),
        payment_method=PaymentMethod.DEBT,
    )
    db.add(a_inv)
    await db.flush()
    a_debt = Debt(
        tenant_id=tenant.id,
        invoice_id=a_inv.id,
        customer_id=a_customer.id,
        total_amount=Decimal("100"),
        paid_amount=Decimal("0"),
        issued_on=today,
        due_on=today + timedelta(days=10),
        status=DebtStatus.GREEN,
    )

    # B için borç
    b_inv = Invoice(
        tenant_id=tenant_b.id,
        customer_id=b_customer.id,
        total=Decimal("200"),
        payment_method=PaymentMethod.DEBT,
    )
    db.add(b_inv)
    await db.flush()
    b_debt = Debt(
        tenant_id=tenant_b.id,
        invoice_id=b_inv.id,
        customer_id=b_customer.id,
        total_amount=Decimal("200"),
        paid_amount=Decimal("0"),
        issued_on=today,
        due_on=today + timedelta(days=10),
        status=DebtStatus.GREEN,
    )
    db.add_all([a_debt, b_debt])
    await db.commit()

    a_debts = (await auth_client.get("/api/v1/debts")).json()
    assert len(a_debts) == 1
    assert float(a_debts[0]["total_amount"]) == 100.0

    b_debts = (await auth_client_b.get("/api/v1/debts")).json()
    assert len(b_debts) == 1
    assert float(b_debts[0]["total_amount"]) == 200.0

    # Cross-tenant ID erişimi
    a_get_b = await auth_client.get(f"/api/v1/debts/{b_debt.id}")
    assert a_get_b.status_code == 404


@pytest.mark.asyncio
async def test_cannot_pay_other_tenant_debt(auth_client, db, tenant_b):
    """Tenant A, Tenant B'nin borç ID'sine ödeme yapamaz."""
    today = date.today()
    b_customer = Customer(name="B Borçlu", tenant_id=tenant_b.id)
    db.add(b_customer)
    await db.commit()
    await db.refresh(b_customer)

    b_inv = Invoice(
        tenant_id=tenant_b.id,
        customer_id=b_customer.id,
        total=Decimal("50"),
        payment_method=PaymentMethod.DEBT,
    )
    db.add(b_inv)
    await db.flush()
    b_debt = Debt(
        tenant_id=tenant_b.id,
        invoice_id=b_inv.id,
        customer_id=b_customer.id,
        total_amount=Decimal("50"),
        paid_amount=Decimal("0"),
        issued_on=today,
        due_on=today + timedelta(days=10),
        status=DebtStatus.GREEN,
    )
    db.add(b_debt)
    await db.commit()
    await db.refresh(b_debt)

    # Tenant A, B'nin borç ID'siyle ödeme yapmayı dener
    resp = await auth_client.post(
        "/api/v1/debts/payments",
        json={"debt_id": str(b_debt.id), "amount": "10"},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_reports_only_show_own_tenant_data(
    auth_client, auth_client_b, db, tenant, tenant_b
):
    """Rapor /summary sadece kendi tenant'ının fatura/borçlarını sayar."""
    a_customer = Customer(name="A", tenant_id=tenant.id)
    b_customer = Customer(name="B", tenant_id=tenant_b.id)
    db.add_all([a_customer, b_customer])
    await db.commit()
    await db.refresh(a_customer)
    await db.refresh(b_customer)

    db.add_all(
        [
            Invoice(
                tenant_id=tenant.id,
                customer_id=a_customer.id,
                total=Decimal("100"),
                payment_method=PaymentMethod.CASH,
            ),
            Invoice(
                tenant_id=tenant_b.id,
                customer_id=b_customer.id,
                total=Decimal("999"),
                payment_method=PaymentMethod.CASH,
            ),
        ]
    )
    await db.commit()

    a_summary = (await auth_client.get("/api/v1/reports/summary")).json()
    assert float(a_summary["total_sales"]) == 100.0

    b_summary = (await auth_client_b.get("/api/v1/reports/summary")).json()
    assert float(b_summary["total_sales"]) == 999.0


@pytest.mark.asyncio
async def test_platform_owner_cannot_access_tenant_data_endpoints(
    app_client, db
):
    """platform_owner login olabilir ama tenant data endpoint'lerine 403 alır."""
    from app.services.user_service import create_platform_owner

    await create_platform_owner(db, "owner@platform.com", "Platform Sahibi", "StrongPass123!")

    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "owner@platform.com", "password": "StrongPass123!"},
    )
    assert login.status_code == 200, login.text
    token = login.json()["access_token"]

    # platform_owner data endpoint'lerine giremez
    resp = await app_client.get(
        "/api/v1/customers", headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 403

    # Ama /sudo/tenants'a girebilir
    resp = await app_client.get(
        "/api/v1/sudo/tenants", headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_sudo_can_create_tenant_with_generated_password(app_client, db):
    """platform_owner /sudo/tenants ile yeni işletme yaratır, parola yanıtta döner,
    yeni sahip o parolayla giriş yapabilir."""
    from app.services.user_service import create_platform_owner

    await create_platform_owner(db, "po@platform.com", "PO", "StrongPass123!")
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "po@platform.com", "password": "StrongPass123!"},
    )
    sudo_token = login.json()["access_token"]

    resp = await app_client.post(
        "/api/v1/sudo/tenants",
        headers={"Authorization": f"Bearer {sudo_token}"},
        json={
            "business_name": "Yeni Toptan",
            "owner_email": "yeni@example.com",
            "owner_full_name": "Yeni Sahibi",
            "contact_phone": "05551112233",
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["tenant"]["name"] == "Yeni Toptan"
    assert body["tenant"]["status"] == "approved"
    assert body["tenant"]["is_active"] is True
    assert body["owner_email"] == "yeni@example.com"
    assert len(body["generated_password"]) >= 10

    # Üretilen parolayla yeni sahip giriş yapabilir
    new_login = await app_client.post(
        "/api/v1/auth/login",
        json={
            "email": "yeni@example.com",
            "password": body["generated_password"],
        },
    )
    assert new_login.status_code == 200, new_login.text


@pytest.mark.asyncio
async def test_sudo_create_tenant_rejects_duplicate_email(app_client, db, user):
    """Aynı e-posta ile ikinci tenant yaratılamaz (409)."""
    from app.services.user_service import create_platform_owner

    await create_platform_owner(db, "po2@platform.com", "PO2", "StrongPass123!")
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "po2@platform.com", "password": "StrongPass123!"},
    )
    sudo_token = login.json()["access_token"]

    resp = await app_client.post(
        "/api/v1/sudo/tenants",
        headers={"Authorization": f"Bearer {sudo_token}"},
        json={
            "business_name": "Çakışan",
            "owner_email": "admin@example.com",
            "owner_full_name": "Xx",
        },
    )
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_tenant_owner_cannot_create_tenant(auth_client):
    """Tenant sahibi /sudo/tenants çağıramaz (403)."""
    resp = await auth_client.post(
        "/api/v1/sudo/tenants",
        json={
            "business_name": "Yetkisiz",
            "owner_email": "x@example.com",
            "owner_full_name": "Xx",
        },
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_login_blocked_when_paid_until_expired(app_client, db, tenant, user):
    """Tenant.paid_until geçmişse login 403 döner."""
    from datetime import date, timedelta

    tenant.paid_until = date.today() - timedelta(days=1)
    await db.commit()

    resp = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    assert resp.status_code == 403
    assert "süresi doldu" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_ok_when_paid_until_future(app_client, db, tenant, user):
    """Tenant.paid_until ilerideyse login geçer."""
    from datetime import date, timedelta

    tenant.paid_until = date.today() + timedelta(days=30)
    await db.commit()

    resp = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_sudo_can_set_paid_until(app_client, db, user):
    """platform_owner /sudo/tenants/{id} PATCH ile paid_until ayarlayabilir."""
    from app.services.user_service import create_platform_owner

    await create_platform_owner(db, "po3@platform.com", "PO3", "StrongPass123!")
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "po3@platform.com", "password": "StrongPass123!"},
    )
    sudo_token = login.json()["access_token"]

    resp = await app_client.patch(
        f"/api/v1/sudo/tenants/{user.tenant_id}",
        headers={"Authorization": f"Bearer {sudo_token}"},
        json={"paid_until": "2027-01-01"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["paid_until"] == "2027-01-01"
