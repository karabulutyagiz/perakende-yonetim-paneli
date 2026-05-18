"""Platform yöneticisi (superuser) endpoint'leri — tenant yönetimi."""
import secrets
import string
from datetime import date
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select

from app.api.deps import CurrentPlatformOwner, DBSession
from app.models.customer import Customer
from app.models.tenant import Tenant, TenantStatus
from app.services import user_service

router = APIRouter(prefix="/sudo", tags=["sudo"])


# 12 karakterlik güçlü ama akılda kalır (ambiguous karakterler atılmış: 0/O, 1/l/I)
_PASSWORD_ALPHABET = "".join(
    set(string.ascii_letters + string.digits) - set("0OoIl1")
)


def _generate_password(length: int = 12) -> str:
    return "".join(secrets.choice(_PASSWORD_ALPHABET) for _ in range(length))


class TenantOut(BaseModel):
    id: str
    name: str
    contact_email: str | None
    contact_phone: str | None
    logo_url: str | None
    status: str
    is_active: bool
    paid_until: str | None  # ISO YYYY-MM-DD
    created_at: str


class CreateTenantRequest(BaseModel):
    business_name: str = Field(min_length=2, max_length=255)
    owner_email: EmailStr
    owner_full_name: str = Field(min_length=2, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    logo_url: str | None = Field(default=None, max_length=1024)
    paid_until: date | None = None


class UpdateTenantRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    logo_url: str | None = Field(default=None, max_length=1024)
    paid_until: date | None = None


class CreateTenantResponse(BaseModel):
    tenant: TenantOut
    owner_email: str
    generated_password: str  # SADECE BU YANITTA döner — tekrar gösterilmez


class CreateMarketRequest(BaseModel):
    market_name: str = Field(min_length=2, max_length=255)
    wholesaler_tenant_id: UUID
    owner_email: EmailStr
    owner_full_name: str = Field(min_length=2, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    address: str | None = Field(default=None, max_length=2000)


class CreateMarketResponse(BaseModel):
    customer_id: str
    market_name: str
    wholesaler_tenant_id: str
    wholesaler_name: str
    owner_email: str
    generated_password: str


def _to_out(t: Tenant) -> TenantOut:
    return TenantOut(
        id=str(t.id),
        name=t.name,
        contact_email=t.contact_email,
        contact_phone=t.contact_phone,
        logo_url=t.logo_url,
        status=t.status.value,
        is_active=t.is_active,
        paid_until=t.paid_until.isoformat() if t.paid_until else None,
        created_at=t.created_at.isoformat() if t.created_at else "",
    )


@router.post(
    "/tenants",
    response_model=CreateTenantResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_tenant(
    payload: CreateTenantRequest, db: DBSession, _: CurrentPlatformOwner
) -> CreateTenantResponse:
    """Yeni işletme + sahibi yarat. Manuel onboarding — tenant doğrudan APPROVED açılır.

    Üretilen parola yalnızca bu yanıtta döner; veritabanında Argon2 hash'lenmiş hâli tutulur.
    """
    existing = await user_service.get_by_email(db, payload.owner_email)
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu e-posta zaten kayıtlı",
        )

    tenant = Tenant(
        name=payload.business_name,
        contact_email=payload.owner_email.lower(),
        contact_phone=payload.contact_phone,
        logo_url=payload.logo_url,
        paid_until=payload.paid_until,
        status=TenantStatus.APPROVED,
        is_active=True,
    )
    db.add(tenant)
    await db.flush()

    password = _generate_password()
    await user_service.create_tenant_owner(
        db,
        tenant_id=tenant.id,
        email=payload.owner_email,
        full_name=payload.owner_full_name,
        password=password,
    )
    await db.refresh(tenant)
    return CreateTenantResponse(
        tenant=_to_out(tenant),
        owner_email=payload.owner_email.lower(),
        generated_password=password,
    )


@router.post(
    "/markets",
    response_model=CreateMarketResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_market(
    payload: CreateMarketRequest,
    db: DBSession,
    _: CurrentPlatformOwner,
) -> CreateMarketResponse:
    existing = await user_service.get_by_email(db, payload.owner_email)
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu e-posta zaten kayıtlı",
        )

    wholesaler = await db.get(Tenant, payload.wholesaler_tenant_id)
    if wholesaler is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Toptancı bulunamadı",
        )
    if wholesaler.status != TenantStatus.APPROVED or not wholesaler.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Seçilen toptancı aktif ve onaylı olmalı",
        )

    customer = Customer(
        tenant_id=wholesaler.id,
        name=payload.market_name,
        phone=payload.contact_phone,
        address=payload.address,
    )
    db.add(customer)
    await db.flush()

    password = _generate_password()
    await user_service.create_customer_user(
        db,
        tenant_id=wholesaler.id,
        customer=customer,
        email=payload.owner_email,
        password=password,
        full_name=payload.owner_full_name,
    )
    await db.commit()
    await db.refresh(customer)

    return CreateMarketResponse(
        customer_id=str(customer.id),
        market_name=customer.name,
        wholesaler_tenant_id=str(wholesaler.id),
        wholesaler_name=wholesaler.name,
        owner_email=payload.owner_email.lower(),
        generated_password=password,
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


@router.patch("/tenants/{tenant_id}", response_model=TenantOut)
async def update_tenant(
    tenant_id: UUID,
    payload: UpdateTenantRequest,
    db: DBSession,
    _: CurrentPlatformOwner,
) -> TenantOut:
    """Tenant alanlarını (ad, logo, telefon) günceller."""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="İşletme bulunamadı")
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(tenant, field, value)
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
