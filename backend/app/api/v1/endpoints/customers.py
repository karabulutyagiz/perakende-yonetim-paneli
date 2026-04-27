from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.customer import CustomerCreate, CustomerOut, CustomerUpdate
from app.services import customer_service
from app.websockets.hub import hub

router = APIRouter(prefix="/customers", tags=["customers"])


@router.get("", response_model=list[CustomerOut])
async def list_customers(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    search: str | None = None,
) -> list[CustomerOut]:
    customers = await customer_service.list_all(db, tenant_id, search)
    return [CustomerOut.model_validate(c) for c in customers]


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
    return CustomerOut.model_validate(customer)


@router.post("", response_model=CustomerOut, status_code=status.HTTP_201_CREATED)
async def create_customer(
    payload: CustomerCreate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> CustomerOut:
    customer = await customer_service.create(db, tenant_id, payload)
    out = CustomerOut.model_validate(customer)
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
    updated = await customer_service.update(db, customer, payload)
    out = CustomerOut.model_validate(updated)
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
