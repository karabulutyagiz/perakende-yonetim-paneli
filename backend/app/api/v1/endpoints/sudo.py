"""Platform yöneticisi (superuser) endpoint'leri — tenant yönetimi."""
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from app.api.deps import CurrentPlatformOwner, DBSession
from app.models.tenant import Tenant, TenantStatus

router = APIRouter(prefix="/sudo", tags=["sudo"])


class TenantOut(BaseModel):
    id: str
    name: str
    contact_email: str | None
    contact_phone: str | None
    status: str
    is_active: bool
    created_at: str


def _to_out(t: Tenant) -> TenantOut:
    return TenantOut(
        id=str(t.id),
        name=t.name,
        contact_email=t.contact_email,
        contact_phone=t.contact_phone,
        status=t.status.value,
        is_active=t.is_active,
        created_at=t.created_at.isoformat() if t.created_at else "",
    )


@router.get("/tenants", response_model=list[TenantOut])
async def list_tenants(
    db: DBSession,
    _: CurrentPlatformOwner,
    status_filter: str | None = None,
) -> list[TenantOut]:
    stmt = select(Tenant).order_by(Tenant.created_at.desc())
    if status_filter:
        try:
            stmt = stmt.where(Tenant.status == TenantStatus(status_filter))
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"geçersiz statü: {status_filter}",
            )
    rows = (await db.execute(stmt)).scalars().all()
    return [_to_out(t) for t in rows]


@router.post("/tenants/{tenant_id}/approve", response_model=TenantOut)
async def approve_tenant(
    tenant_id: UUID, db: DBSession, _: CurrentPlatformOwner
) -> TenantOut:
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="İşletme bulunamadı")
    tenant.status = TenantStatus.APPROVED
    tenant.is_active = True
    await db.commit()
    await db.refresh(tenant)
    return _to_out(tenant)


@router.post("/tenants/{tenant_id}/suspend", response_model=TenantOut)
async def suspend_tenant(
    tenant_id: UUID, db: DBSession, _: CurrentPlatformOwner
) -> TenantOut:
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="İşletme bulunamadı")
    tenant.status = TenantStatus.SUSPENDED
    tenant.is_active = False
    await db.commit()
    await db.refresh(tenant)
    return _to_out(tenant)


@router.delete("/tenants/{tenant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant(
    tenant_id: UUID, db: DBSession, _: CurrentPlatformOwner
) -> None:
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="İşletme bulunamadı")
    await db.delete(tenant)
    await db.commit()
