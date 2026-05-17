from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.deps import (
    CurrentCustomerUser,
    CurrentScopedTenantId,
    CurrentTenantScopedUser,
    CurrentTenantUser,
    DBSession,
)
from app.models.order import OrderStatus
from app.schemas.order import ConvertOrderToInvoiceRequest, OrderCreate, OrderOut
from app.services import order_service
from app.websockets.hub import hub

router = APIRouter(prefix="/orders", tags=["orders"])


def _to_out(order) -> OrderOut:  # type: ignore[no-untyped-def]
    return OrderOut.model_validate(order)


@router.get("", response_model=list[OrderOut])
async def list_orders(
    db: DBSession,
    tenant_id: CurrentScopedTenantId,
    current_user: CurrentTenantScopedUser,
    status_filter: OrderStatus | None = None,
) -> list[OrderOut]:
    customer_id = current_user.customer_id if current_user.role.value == "customer" else None
    orders = await order_service.list_orders(
        db,
        tenant_id=tenant_id,
        customer_id=customer_id,
        status_filter=status_filter,
    )
    return [_to_out(order) for order in orders]


@router.get("/mine", response_model=list[OrderOut])
async def list_my_orders(
    db: DBSession,
    tenant_id: CurrentScopedTenantId,
    current_user: CurrentCustomerUser,
    status_filter: OrderStatus | None = None,
) -> list[OrderOut]:
    orders = await order_service.list_orders(
        db,
        tenant_id=tenant_id,
        customer_id=current_user.customer_id,
        status_filter=status_filter,
    )
    return [_to_out(order) for order in orders]


@router.get("/{order_id}", response_model=OrderOut)
async def get_order(
    order_id: UUID,
    db: DBSession,
    tenant_id: CurrentScopedTenantId,
    current_user: CurrentTenantScopedUser,
) -> OrderOut:
    order = await order_service.get(db, order_id, tenant_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sipariş bulunamadı")
    if current_user.customer_id is not None and order.customer_id != current_user.customer_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sipariş bulunamadı")
    return _to_out(order)


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
async def create_order(
    payload: OrderCreate,
    db: DBSession,
    current_user: CurrentCustomerUser,
) -> OrderOut:
    order = await order_service.create_for_customer(db, customer_user=current_user, data=payload)
    out = _to_out(order)
    assert current_user.tenant_id is not None
    await hub.broadcast("order.created", out.model_dump(mode="json"), current_user.tenant_id)
    return out


@router.post("/{order_id}/convert-to-invoice", response_model=OrderOut)
async def convert_order_to_invoice(
    order_id: UUID,
    payload: ConvertOrderToInvoiceRequest,
    db: DBSession,
    tenant_id: CurrentScopedTenantId,
    _: CurrentTenantUser,
) -> OrderOut:
    order = await order_service.get(db, order_id, tenant_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sipariş bulunamadı")
    updated = await order_service.convert_to_invoice(db, order=order, payload=payload)
    out = _to_out(updated)
    await hub.broadcast("order.updated", out.model_dump(mode="json"), tenant_id)
    if updated.invoice_id is not None:
        await hub.broadcast("invoice.created", {"invoice_id": str(updated.invoice_id)}, tenant_id)
        if payload.debt_amount > 0:
            await hub.broadcast(
                "debt.created",
                {"invoice_id": str(updated.invoice_id), "order_id": str(updated.id)},
                tenant_id,
            )
        await hub.broadcast("stock.changed", {"order_id": str(updated.id)}, tenant_id)
    return out


@router.post("/{order_id}/cancel", response_model=OrderOut)
async def cancel_order(
    order_id: UUID,
    db: DBSession,
    tenant_id: CurrentScopedTenantId,
    _: CurrentTenantUser,
) -> OrderOut:
    order = await order_service.get(db, order_id, tenant_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sipariş bulunamadı")
    updated = await order_service.cancel(db, order=order)
    out = _to_out(updated)
    await hub.broadcast("order.updated", out.model_dump(mode="json"), tenant_id)
    return out
