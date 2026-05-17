from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.invoice import InvoiceCreate, InvoiceOut
from app.services import invoice_service
from app.websockets.hub import hub

router = APIRouter(prefix="/invoices", tags=["invoices"])


def _to_out(invoice) -> InvoiceOut:  # type: ignore[no-untyped-def]
    out = InvoiceOut.model_validate(invoice)
    if getattr(invoice, "order", None) is not None:
        out.order_id = invoice.order.id
        out.order_number = invoice.order.order_number
    return out


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
    return [_to_out(i) for i in invoices]


@router.get("/{invoice_id}", response_model=InvoiceOut)
async def get_invoice(
    invoice_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.get(db, invoice_id, tenant_id)
    if not invoice:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fatura bulunamadı")
    return _to_out(invoice)


@router.post("", response_model=InvoiceOut, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    payload: InvoiceCreate, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.create(db, tenant_id, payload)
    out = _to_out(invoice)
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
