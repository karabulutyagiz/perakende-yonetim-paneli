from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.common import ORMModel
from app.schemas.customer import CustomerOut
from app.schemas.debt import (
    CustomerDebtSummary,
    DebtOut,
    DebtPaymentCreate,
    DebtPaymentOut,
)
from app.services import debt_service
from app.websockets.hub import hub

router = APIRouter(prefix="/debts", tags=["debts"])


def _to_out(view) -> DebtOut:  # type: ignore[no-untyped-def]
    d = view.debt
    latest_payment = d.payments[0] if getattr(d, "payments", None) else None
    customer_out = (
        CustomerOut.model_validate(d.customer) if getattr(d, "customer", None) else None
    )
    return DebtOut(
        id=d.id,
        created_at=d.created_at,
        updated_at=d.updated_at,
        invoice_id=d.invoice_id,
        customer_id=d.customer_id,
        total_amount=d.total_amount,
        paid_amount=d.paid_amount,
        last_payment_amount=latest_payment.amount if latest_payment is not None else 0,
        remaining=d.total_amount - d.paid_amount,
        issued_on=d.issued_on,
        due_on=d.due_on,
        last_payment_on=latest_payment.paid_on if latest_payment is not None else None,
        days_left=view.days_left,
        status=d.status,
        customer=customer_out,
    )


@router.get("", response_model=list[DebtOut])
async def list_debts(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    customer_id: UUID | None = None,
    only_open: bool = True,
) -> list[DebtOut]:
    views = await debt_service.list_debts(db, tenant_id, customer_id, only_open)
    return [_to_out(v) for v in views]


@router.get("/summary", response_model=list[CustomerDebtSummary])
async def debt_summary(
    db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> list[CustomerDebtSummary]:
    rows = await debt_service.customer_summary(db, tenant_id)
    return [
        CustomerDebtSummary(
            customer=CustomerOut.model_validate(r["customer"]),
            total_debt=r["total_debt"],
            total_paid=r["total_paid"],
            remaining=r["remaining"],
            debts_count=r["debts_count"],
        )
        for r in rows
    ]


@router.get("/{debt_id}", response_model=DebtOut)
async def get_debt(
    debt_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> DebtOut:
    debt = await debt_service.get(db, debt_id, tenant_id)
    if not debt:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Borç bulunamadı")
    return _to_out(debt_service.DebtView(debt=debt, days_left=debt_service.days_left(debt.due_on)))


class PaymentsResponse(ORMModel):
    payments: list[DebtPaymentOut]


@router.post("/payments", response_model=PaymentsResponse, status_code=status.HTTP_201_CREATED)
async def record_payment(
    payload: DebtPaymentCreate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> PaymentsResponse:
    payments = await debt_service.record_payment(db, tenant_id, payload)
    out = PaymentsResponse(payments=[DebtPaymentOut.model_validate(p) for p in payments])
    await hub.broadcast("debt.payment", out.model_dump(mode="json"), tenant_id)
    return out


@router.post("/recompute", status_code=status.HTTP_200_OK)
async def recompute_statuses(
    db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> dict[str, int]:
    changed = await debt_service.recompute_all_statuses(db, tenant_id)
    if changed:
        await hub.broadcast("debt.recomputed", {"changed": changed}, tenant_id)
    return {"changed": changed}
