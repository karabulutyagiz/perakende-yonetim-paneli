"""Borç takibi: durum hesabı, ödeme dağıtımı, günlük senkronizasyon."""
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.customer import Customer
from app.models.debt import Debt, DebtPayment, DebtStatus
from app.schemas.debt import DebtPaymentCreate


def compute_status(due_on: date, remaining: Decimal, today: date | None = None) -> DebtStatus:
    if remaining <= 0:
        return DebtStatus.PAID
    today = today or date.today()
    delta = (due_on - today).days
    if delta < 0:
        return DebtStatus.OVERDUE
    if delta <= 3:
        return DebtStatus.RED
    if delta <= 7:
        return DebtStatus.YELLOW
    return DebtStatus.GREEN


def days_left(due_on: date, today: date | None = None) -> int:
    return (due_on - (today or date.today())).days


@dataclass
class DebtView:
    debt: Debt
    days_left: int


async def list_debts(
    db: AsyncSession,
    tenant_id: UUID,
    customer_id: UUID | None = None,
    only_open: bool = True,
) -> list[DebtView]:
    stmt = (
        select(Debt)
        .options(selectinload(Debt.payments))
        .where(Debt.tenant_id == tenant_id)
        .order_by(Debt.due_on.asc())
    )
    if customer_id:
        stmt = stmt.where(Debt.customer_id == customer_id)
    if only_open:
        stmt = stmt.where(Debt.status != DebtStatus.PAID)
    debts = list((await db.execute(stmt)).scalars().all())
    return [DebtView(debt=d, days_left=days_left(d.due_on)) for d in debts]


async def get(db: AsyncSession, debt_id: UUID, tenant_id: UUID) -> Debt | None:
    stmt = (
        select(Debt)
        .options(selectinload(Debt.payments))
        .where(Debt.id == debt_id, Debt.tenant_id == tenant_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def customer_summary(db: AsyncSession, tenant_id: UUID) -> list[dict]:
    """Her müşterinin açık toplam borcu."""
    stmt = (
        select(
            Customer,
            func.coalesce(func.sum(Debt.total_amount), 0),
            func.coalesce(func.sum(Debt.paid_amount), 0),
            func.count(Debt.id),
        )
        .join(Debt, Debt.customer_id == Customer.id)
        .where(Debt.status != DebtStatus.PAID, Debt.tenant_id == tenant_id)
        .group_by(Customer.id)
        .order_by(Customer.name)
    )
    rows = (await db.execute(stmt)).all()
    out = []
    for customer, total, paid, cnt in rows:
        out.append(
            {
                "customer": customer,
                "total_debt": Decimal(total or 0),
                "total_paid": Decimal(paid or 0),
                "remaining": Decimal(total or 0) - Decimal(paid or 0),
                "debts_count": int(cnt or 0),
            }
        )
    return out


async def record_payment(
    db: AsyncSession, tenant_id: UUID, data: DebtPaymentCreate
) -> list[DebtPayment]:
    """Ödeme kaydet. Eğer debt_id verilirse o borca yazılır,
    customer_id verilirse en eski açık borçtan başlayarak dağıtılır."""
    if data.amount <= 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Ödeme tutarı sıfırdan büyük olmalı")
    paid_on = data.paid_on or date.today()

    payments: list[DebtPayment] = []

    if data.debt_id:
        debt = await get(db, data.debt_id, tenant_id)
        if not debt:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Borç bulunamadı")
        _apply_payment(db, debt, data.amount, paid_on, payments)

    elif data.customer_id:
        stmt = (
            select(Debt)
            .options(selectinload(Debt.payments))
            .where(
                Debt.customer_id == data.customer_id,
                Debt.tenant_id == tenant_id,
                Debt.status != DebtStatus.PAID,
            )
            .order_by(Debt.due_on.asc())
        )
        open_debts = list((await db.execute(stmt)).scalars().all())
        remaining_amount = data.amount
        for debt in open_debts:
            if remaining_amount <= 0:
                break
            debt_remaining = debt.total_amount - debt.paid_amount
            pay = min(debt_remaining, remaining_amount)
            _apply_payment(db, debt, pay, paid_on, payments)
            remaining_amount -= pay
        if remaining_amount > 0:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Ödeme tutarı toplam borçtan fazla",
            )
    else:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "debt_id veya customer_id zorunlu"
        )

    await db.commit()
    return payments


def _apply_payment(
    db: AsyncSession,
    debt: Debt,
    amount: Decimal,
    paid_on: date,
    sink: list[DebtPayment],
) -> None:
    remaining = debt.total_amount - debt.paid_amount
    if amount > remaining:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Ödeme tutarı kalan borçtan fazla (kalan {remaining})",
        )
    debt.paid_amount = (debt.paid_amount or Decimal("0")) + amount
    debt.status = compute_status(debt.due_on, debt.total_amount - debt.paid_amount)
    payment = DebtPayment(debt_id=debt.id, amount=amount, paid_on=paid_on)
    db.add(payment)
    sink.append(payment)


async def recompute_all_statuses(db: AsyncSession, tenant_id: UUID | None = None) -> int:
    """Günlük cron: açık borçların durumunu yeniden hesapla.
    tenant_id None ise tüm tenantlar için (günlük cron)."""
    stmt = select(Debt).where(Debt.status != DebtStatus.PAID)
    if tenant_id is not None:
        stmt = stmt.where(Debt.tenant_id == tenant_id)
    debts = list((await db.execute(stmt)).scalars().all())
    changed = 0
    for debt in debts:
        remaining = debt.total_amount - debt.paid_amount
        new_status = compute_status(debt.due_on, remaining)
        if debt.status != new_status:
            debt.status = new_status
            changed += 1
    if changed:
        await db.commit()
    return changed
