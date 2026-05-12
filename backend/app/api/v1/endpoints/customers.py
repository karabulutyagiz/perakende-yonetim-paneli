from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.customer import CustomerCreate, CustomerOut, CustomerUpdate
from app.services import customer_service
from app.websockets.hub import hub

router = APIRouter(prefix="/customers", tags=["customers"])


def _to_out(customer) -> CustomerOut:  # type: ignore[no-untyped-def]
    out = CustomerOut.model_validate(customer)
    out.has_account = customer.account is not None
    out.account_email = customer.account.email if customer.account is not None else None
    out.account_is_active = customer.account.is_active if customer.account is not None else None
    return out


@router.get("", response_model=list[CustomerOut])
async def list_customers(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    search: str | None = None,
) -> list[CustomerOut]:
    customers = await customer_service.list_all(db, tenant_id, search)
    return [_to_out(c) for c in customers]


@router.get("/{customer_id}", response_model=CustomerOut)
async def get_customer(
    customer_id: UUID,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> CustomerOut:
    customer = await customer_service.get(db, customer_id, tenant_id)
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Müşteri bulunamadı")
    return _to_out(customer)


@router.post("", response_model=CustomerOut, status_code=status.HTTP_201_CREATED)
async def create_customer(
    payload: CustomerCreate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> CustomerOut:
    try:
        customer = await customer_service.create(db, tenant_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    out = _to_out(customer)
    await hub.broadcast("customer.created", out.model_dump(mode="json"), tenant_id)
    return out


@router.put("/{customer_id}", response_model=CustomerOut)
async def update_customer(
    customer_id: UUID,
    payload: CustomerUpdate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> CustomerOut:
    customer = await customer_service.get(db, customer_id, tenant_id)
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Müşteri bulunamadı")
    try:
        updated = await customer_service.update(db, customer, payload)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    out = _to_out(updated)
    await hub.broadcast("customer.updated", out.model_dump(mode="json"), tenant_id)
    return out


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: UUID,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> None:
    customer = await customer_service.get(db, customer_id, tenant_id)
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Müşteri bulunamadı")
    await customer_service.delete(db, customer)
    await hub.broadcast("customer.deleted", {"id": str(customer_id)}, tenant_id)
