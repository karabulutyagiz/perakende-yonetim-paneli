from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.invoice import InvoiceCreate, InvoiceOut
from app.services import invoice_service
from app.websockets.hub import hub

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.get("", response_model=list[InvoiceOut])
async def list_invoices(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    customer_id: UUID | None = None,
    limit: int = Query(100, le=500),
    offset: int = 0,
) -> list[InvoiceOut]:
    invoices = await invoice_service.list_invoices(db, tenant_id, customer_id, limit, offset)
    return [InvoiceOut.model_validate(i) for i in invoices]


@router.get("/{invoice_id}", response_model=InvoiceOut)
async def get_invoice(
    invoice_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.get(db, invoice_id, tenant_id)
    if not invoice:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fatura bulunamadı")
    return InvoiceOut.model_validate(invoice)


@router.post("", response_model=InvoiceOut, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    payload: InvoiceCreate, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> InvoiceOut:
    invoice = await invoice_service.create(db, tenant_id, payload)
    out = InvoiceOut.model_validate(invoice)
    await hub.broadcast("invoice.created", out.model_dump(mode="json"), tenant_id)
    # Stok değişikliği oldu — ürünler yeniden çekilsin
    await hub.broadcast("stock.changed", {"invoice_id": str(invoice.id)}, tenant_id)
    return out
