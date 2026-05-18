from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.models.order import Order
from app.schemas.customer import CustomerOut
from app.schemas.invoice import InvoiceCreate, InvoiceItemOut, InvoiceOut
from app.services import invoice_service
from app.websockets.hub import hub

router = APIRouter(prefix="/invoices", tags=["invoices"])


def _to_out(
    invoice,
    order_id: UUID | None = None,
    order_number: str | None = None,
) -> InvoiceOut:  # type: ignore[no-untyped-def]
    return InvoiceOut(
        id=invoice.id,
        created_at=invoice.created_at,
        updated_at=invoice.updated_at,
        order_id=order_id,
        order_number=order_number,
        customer_id=invoice.customer_id,
        total=invoice.total,
        cash_amount=invoice.cash_amount,
        card_amount=invoice.card_amount,
        debt_amount=invoice.debt_amount,
        payment_method=invoice.payment_method,
        note=invoice.note,
        customer=(
            CustomerOut.model_validate(invoice.customer) if getattr(invoice, "customer", None) else None
        ),
        items=[InvoiceItemOut.model_validate(item) for item in getattr(invoice, "items", [])],
    )


async def _order_meta_by_invoice_id(
    db: DBSession, tenant_id: UUID, invoice_ids: list[UUID]
) -> dict[UUID, tuple[UUID, str]]:
    if not invoice_ids:
        return {}
    rows = (
        await db.execute(
            select(Order.invoice_id, Order.id)
            .where(Order.tenant_id == tenant_id, Order.invoice_id.in_(invoice_ids))
        )
    ).all()
    return {
        invoice_id: (order_id, str(int(order_id.hex, 16) % 100000000).zfill(8))
        for invoice_id, order_id in rows
        if invoice_id is not None
    }


@router.get("", response_model=list[InvoiceOut])
async def list_invoices(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    customer_id: UUID | None = None,
    only_order_backed: bool = True,
    limit: int = Query(100, le=500),
    offset: int = 0,
) -> list[InvoiceOut]:
    invoices = await invoice_service.list_invoices(
        db,
        tenant_id,
        customer_id,
        limit,
        offset,
        only_order_backed,
    )
    order_meta = await _order_meta_by_invoice_id(db, tenant_id, [i.id for i in invoices])
    return [
        _to_out(
            i,
            order_meta.get(i.id, (None, None))[0],
            order_meta.get(i.id, (None, None))[1],
        )
        for i in invoices
    ]


@router.get("/{invoice_id}", response_model=InvoiceOut)
async def get_invoice(
    invoice_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.get(db, invoice_id, tenant_id)
    if not invoice:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fatura bulunamadı")
    order_meta = await _order_meta_by_invoice_id(db, tenant_id, [invoice.id])
    meta = order_meta.get(invoice.id)
    return _to_out(invoice, meta[0] if meta else None, meta[1] if meta else None)


@router.post("", response_model=InvoiceOut, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    payload: InvoiceCreate, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.create(db, tenant_id, payload)
    order_meta = await _order_meta_by_invoice_id(db, tenant_id, [invoice.id])
    meta = order_meta.get(invoice.id)
    out = _to_out(invoice, meta[0] if meta else None, meta[1] if meta else None)
    await hub.broadcast("invoice.created", out.model_dump(mode="json"), tenant_id)
    if invoice.debt_amount > 0:
        await hub.broadcast(
            "debt.created",
            {"invoice_id": str(invoice.id)},
            tenant_id,
        )
    # Stok değişikliği oldu — ürünler yeniden çekilsin
    await hub.broadcast("stock.changed", {"invoice_id": str(invoice.id)}, tenant_id)
    return out
