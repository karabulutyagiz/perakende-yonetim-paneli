from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.services import category_service
from app.websockets.hub import hub

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
async def list_categories(
    db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> list[CategoryOut]:
    categories = await category_service.list_all(db, tenant_id)
    return [CategoryOut.model_validate(c) for c in categories]


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(
    payload: CategoryCreate, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> CategoryOut:
    category = await category_service.create(db, tenant_id, payload)
    out = CategoryOut.model_validate(category)
    await hub.broadcast("category.created", out.model_dump(mode="json"), tenant_id)
    return out


@router.put("/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: UUID,
    payload: CategoryUpdate,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> CategoryOut:
    category = await category_service.get(db, category_id, tenant_id)
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kategori bulunamadı")
    updated = await category_service.update(db, category, payload)
    out = CategoryOut.model_validate(updated)
    await hub.broadcast("category.updated", out.model_dump(mode="json"), tenant_id)
    return out


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: UUID, db: DBSession, tenant_id: CurrentTenantId, _: CurrentTenantUser
) -> None:
    category = await category_service.get(db, category_id, tenant_id)
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kategori bulunamadı")
    await category_service.delete(db, category)
    await hub.broadcast("category.deleted", {"id": str(category_id)}, tenant_id)
