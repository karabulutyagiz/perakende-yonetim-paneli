from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Request, status
from slowapi.util import get_remote_address

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.core.config import settings
from app.core.rate_limit import limiter
from app.schemas.product import (
    PresignUploadRequest,
    PresignUploadResponse,
    ProductCreate,
    ProductOut,
    ProductUpdate,
)
from app.services import product_service, s3_service
from app.websockets.hub import hub

router = APIRouter(prefix="/products", tags=["products"])


def _to_out(product) -> ProductOut:  # type: ignore[no-untyped-def]
    data = ProductOut.model_validate(product)
    data.image_url = s3_service.generate_view_url(product.image_key)
    return data


@router.get("", response_model=list[ProductOut])
async def list_products(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    search: str | None = None,
    category_id: UUID | None = None,
    limit: int = Query(200, le=500),
    offset: int = 0,
) -> list[ProductOut]:
    products = await product_service.list_products(
        db, tenant_id, search, category_id, limit, offset
    )
    return [_to_out(p) for p in products]


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(
    product_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> ProductOut:
    product = await product_service.get(db, product_id, tenant_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ürün bulunamadı")
    return _to_out(product)


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    payload: ProductCreate, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> ProductOut:
    product = await product_service.create(db, tenant_id, payload)
    out = _to_out(product)
    await hub.broadcast("product.created", out.model_dump(mode="json"), tenant_id)
    return out


@router.put("/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: UUID,
    payload: ProductUpdate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> ProductOut:
    product = await product_service.get(db, product_id, tenant_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ürün bulunamadı")
    updated = await product_service.update(db, product, payload)
    out = _to_out(updated)
    await hub.broadcast("product.updated", out.model_dump(mode="json"), tenant_id)
    return out


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> None:
    product = await product_service.get(db, product_id, tenant_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ürün bulunamadı")
    await product_service.delete(db, product)
    await hub.broadcast("product.deleted", {"id": str(product_id)}, tenant_id)


@router.post("/upload-url", response_model=PresignUploadResponse)
@limiter.limit(settings.rate_limit_upload, key_func=get_remote_address)
async def presign_upload(
    request: Request, payload: PresignUploadRequest, _: CurrentTenantUser
) -> PresignUploadResponse:
    url, key = s3_service.generate_upload_url(payload.filename, payload.content_type)
    return PresignUploadResponse(upload_url=url, key=key)
