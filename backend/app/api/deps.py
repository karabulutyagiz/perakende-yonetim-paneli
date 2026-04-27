from typing import Annotated
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import get_db
from app.models.user import User, UserRole
from app.services import user_service

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=True)

DBSession = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    db: DBSession,
    token: Annotated[str, Depends(oauth2_scheme)],
) -> User:
    try:
        payload = decode_token(token, "access")
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="geçersiz token")

    user = await user_service.get_by_id(db, UUID(user_id))
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="kullanıcı bulunamadı")
    if int(payload.get("v", -1)) != user.token_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="oturum sonlandırılmış",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


async def get_current_tenant_user(current_user: CurrentUser) -> User:
    """Tenant'a bağlı bir kullanıcı gerektirir; platform_owner hesabı reddedilir.

    Ayrıca tenant'ın `approved` + `is_active` olmasını kontrol eder.
    """
    if current_user.role != UserRole.TENANT_OWNER or current_user.tenant_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="bu işlem işletme hesabı ister",
        )
    tenant = current_user.tenant
    if tenant is None or not tenant.is_active or tenant.status.value != "approved":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="işletme hesabı aktif değil (onay bekleniyor veya askıya alınmış)",
        )
    return current_user


CurrentTenantUser = Annotated[User, Depends(get_current_tenant_user)]


async def get_current_tenant_id(
    current_user: CurrentTenantUser,
) -> UUID:
    assert current_user.tenant_id is not None
    return current_user.tenant_id


CurrentTenantId = Annotated[UUID, Depends(get_current_tenant_id)]


async def get_current_platform_owner(current_user: CurrentUser) -> User:
    if current_user.role != UserRole.PLATFORM_OWNER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="platform yöneticisi gerekli",
        )
    return current_user


CurrentPlatformOwner = Annotated[User, Depends(get_current_platform_owner)]
