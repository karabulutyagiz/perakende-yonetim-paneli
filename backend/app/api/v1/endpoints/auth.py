from datetime import date

from fastapi import APIRouter, HTTPException, Request, status
from slowapi.util import get_remote_address

from app.api.deps import CurrentUser, DBSession
from app.core.config import settings
from app.core.rate_limit import limiter
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)
from app.models.tenant import TenantStatus
from app.models.user import UserRole
from app.schemas.auth import (
    ChangePasswordRequest,
    CustomerInfo,
    LoginRequest,
    RefreshRequest,
    TenantInfo,
    TokenPair,
    UserMe,
)
from app.services import user_service

router = APIRouter(prefix="/auth", tags=["auth"])


def _issue_tokens(user) -> TokenPair:
    tid = str(user.tenant_id) if user.tenant_id else None
    return TokenPair(
        access_token=create_access_token(str(user.id), user.token_version, tid, user.role.value),
        refresh_token=create_refresh_token(str(user.id), user.token_version, tid, user.role.value),
    )


@router.post("/login", response_model=TokenPair)
@limiter.limit(settings.rate_limit_login, key_func=get_remote_address)
async def login(request: Request, payload: LoginRequest, db: DBSession) -> TokenPair:
    user = await user_service.authenticate(db, payload.email, payload.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta veya parola hatalı",
        )
    # Tenant kullanıcısıysa tenant'ın durumunu kontrol et
    if user.role in {UserRole.TENANT_OWNER, UserRole.CUSTOMER}:
        tenant = user.tenant
        if tenant is None or not tenant.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="İşletme hesabı askıya alınmış",
            )
        if tenant.status == TenantStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="İşletme hesabı henüz onaylanmadı",
            )
        if tenant.status == TenantStatus.SUSPENDED:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="İşletme hesabı askıya alınmış",
            )
        if tenant.paid_until is not None and tenant.paid_until < date.today():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    "Aboneliğinizin süresi doldu "
                    f"({tenant.paid_until.isoformat()}). "
                    "Lütfen platform sahibi ile iletişime geçin."
                ),
            )
    if user.role == UserRole.CUSTOMER and user.customer_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Müşteri hesabı ilişkilendirmesi eksik",
        )
    return _issue_tokens(user)


@router.post("/refresh", response_model=TokenPair)
@limiter.limit(settings.rate_limit_refresh, key_func=get_remote_address)
async def refresh(request: Request, payload: RefreshRequest, db: DBSession) -> TokenPair:
    try:
        data = decode_token(payload.refresh_token, "refresh")
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    user_id = data.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="geçersiz token")

    from uuid import UUID

    user = await user_service.get_by_id(db, UUID(user_id))
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="kullanıcı bulunamadı")

    if int(data.get("v", -1)) != user.token_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="refresh token geçersiz"
        )

    # Refresh token rotation: yeni access + yeni refresh (token_version sabit kalır)
    return _issue_tokens(user)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: CurrentUser, db: DBSession) -> None:
    """Tüm cihazlardaki token'ları (access + refresh) geçersizleştirir."""
    await user_service.bump_token_version(db, current_user)


@router.get("/me", response_model=UserMe)
async def me(current_user: CurrentUser) -> UserMe:
    tenant_info: TenantInfo | None = None
    customer_info: CustomerInfo | None = None
    if current_user.tenant is not None:
        tenant_info = TenantInfo(
            id=str(current_user.tenant.id),
            name=current_user.tenant.name,
            status=current_user.tenant.status.value,
            is_active=current_user.tenant.is_active,
            logo_url=current_user.tenant.logo_url,
        )
    if current_user.customer is not None:
        customer_info = CustomerInfo(
            id=str(current_user.customer.id),
            name=current_user.customer.name,
            phone=current_user.customer.phone,
            address=current_user.customer.address,
        )
    return UserMe(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        role=current_user.role.value,
        tenant=tenant_info,
        customer=customer_info,
    )


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    payload: ChangePasswordRequest,
    current_user: CurrentUser,
    db: DBSession,
) -> None:
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Mevcut parola hatalı"
        )
    await user_service.change_password(db, current_user, payload.new_password)
