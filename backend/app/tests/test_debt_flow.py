"""Borç ödeme dağıtımı — en eski borçtan başlayarak kapatma."""
from datetime import date, timedelta
from decimal import Decimal

import pytest

from app.models import Customer, Debt, DebtStatus, Invoice, PaymentMethod


async def _open_invoice_with_debt(
    db, tenant_id, customer_id, amount: Decimal, days_left: int
) -> Debt:
    today = date.today()
    inv = Invoice(
        tenant_id=tenant_id,
        customer_id=customer_id,
        total=amount,
        payment_method=PaymentMethod.DEBT,
    )
    db.add(inv)
    await db.flush()
    debt = Debt(
        tenant_id=tenant_id,
        invoice_id=inv.id,
        customer_id=customer_id,
        total_amount=amount,
        paid_amount=Decimal("0"),
        issued_on=today - timedelta(days=15 - days_left),
        due_on=today + timedelta(days=days_left),
        status=DebtStatus.GREEN,
    )
    db.add(debt)
    await db.commit()
    await db.refresh(debt)
    return debt


@pytest.mark.asyncio
async def test_payment_distributes_oldest_first(auth_client, db, tenant):
    customer = Customer(name="Mehmet", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)

    # en eski: vade 1 gün sonra, 100₺ — sonra: vade 10 gün sonra, 50₺
    old = await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("100"), days_left=1)
    new = await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("50"), days_left=10)

    resp = await auth_client.post(
        "/api/v1/debts/payments",
        json={"customer_id": str(customer.id), "amount": "120"},
    )
    assert resp.status_code == 201, resp.text

    await db.refresh(old)
    await db.refresh(new)
    assert old.paid_amount == Decimal("100.00")
    assert old.status == DebtStatus.PAID
    assert new.paid_amount == Decimal("20.00")
    assert new.status != DebtStatus.PAID


@pytest.mark.asyncio
async def test_payment_exceeding_total_rejected(auth_client, db, tenant):
    customer = Customer(name="Ayşe", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    debt = await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("50"), days_left=5)

    resp = await auth_client.post(
        "/api/v1/debts/payments",
        json={"customer_id": str(customer.id), "amount": "200"},
    )
    assert resp.status_code == 400
    await db.refresh(debt)
    assert debt.paid_amount == Decimal("0")


@pytest.mark.asyncio
async def test_summary_aggregates_remaining(auth_client, db, tenant):
    customer = Customer(name="Fatma", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("80"), days_left=5)
    await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("40"), days_left=12)

    resp = await auth_client.get("/api/v1/debts/summary")
    assert resp.status_code == 200
    rows = resp.json()
    match = next(r for r in rows if r["customer"]["id"] == str(customer.id))
    assert float(match["total_debt"]) == 120.0
    assert float(match["remaining"]) == 120.0
    assert match["debts_count"] == 2


@pytest.mark.asyncio
async def test_recompute_marks_overdue(auth_client, db, tenant):
    customer = Customer(name="Kerem", tenant_id=tenant.id)
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    debt = await _open_invoice_with_debt(db, tenant.id, customer.id, Decimal("60"), days_left=-5)
    # senaryo: _open_invoice_with_debt hep GREEN başlatıyor — recompute OVERDUE'ya çekmeli
    assert debt.status == DebtStatus.GREEN

    resp = await auth_client.post("/api/v1/debts/recompute")
    assert resp.status_code == 200
    assert resp.json()["changed"] >= 1
    await db.refresh(debt)
    assert debt.status == DebtStatus.OVERDUE
