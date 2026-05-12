from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import hash_password, needs_rehash, verify_password
from app.models.customer import Customer
from app.models.tenant import Tenant, TenantStatus
from app.models.user import User, UserRole


async def get_by_id(db: AsyncSession, user_id: UUID) -> User | None:
    stmt = (
        select(User)
        .options(selectinload(User.tenant), selectinload(User.customer))
        .where(User.id == user_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def get_by_email(db: AsyncSession, email: str) -> User | None:
    """E-posta ile ilk aktif eşleşmeyi döner. (tenant_id, email) composite unique olduğu
    için teorik olarak aynı e-posta farklı tenantlarda olabilir; ama pratikte
    platform_owner tek + tenant_owner tenant başına tek. İlk eşleşme yeterli."""
    stmt = (
        select(User)
        .options(selectinload(User.tenant), selectinload(User.customer))
        .where(User.email == email.lower())
    )
    result = await db.execute(stmt)
    return result.scalars().first()


async def authenticate(db: AsyncSession, email: str, password: str) -> User | None:
    user = await get_by_email(db, email)
    if not user or not user.is_active:
        return None
    if not verify_password(password, user.password_hash):
        return None
    if needs_rehash(user.password_hash):
        user.password_hash = hash_password(password)
        await db.commit()
    return user


async def create_tenant_owner(
    db: AsyncSession,
    tenant_id: UUID,
    email: str,
    full_name: str,
    password: str,
) -> User:
    user = User(
        email=email.lower(),
        full_name=full_name,
        password_hash=hash_password(password),
        is_active=True,
        role=UserRole.TENANT_OWNER,
        tenant_id=tenant_id,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def create_platform_owner(
    db: AsyncSession, email: str, full_name: str, password: str
) -> User:
    user = User(
        email=email.lower(),
        full_name=full_name,
        password_hash=hash_password(password),
        is_active=True,
        role=UserRole.PLATFORM_OWNER,
        tenant_id=None,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def create_customer_user(
    db: AsyncSession,
    *,
    tenant_id: UUID,
    customer: Customer,
    email: str,
    password: str,
    is_active: bool = True,
) -> User:
    user = User(
        email=email.lower(),
        full_name=customer.name,
        password_hash=hash_password(password),
        is_active=is_active,
        role=UserRole.CUSTOMER,
        tenant_id=tenant_id,
        customer_id=customer.id,
    )
    db.add(user)
    await db.flush()
    return user


async def signup_tenant(
    db: AsyncSession,
    business_name: str,
    email: str,
    full_name: str,
    password: str,
    contact_phone: str | None = None,
) -> tuple[Tenant, User]:
    """Yeni işletme + sahibi kayıt eder. Tenant `pending` statüsünde açılır;
    platform_owner onaylayana kadar giriş yapılamaz."""
    tenant = Tenant(
        name=business_name,
        contact_email=email.lower(),
        contact_phone=contact_phone,
        status=TenantStatus.PENDING,
        is_active=True,
    )
    db.add(tenant)
    await db.flush()
    user = User(
        email=email.lower(),
        full_name=full_name,
        password_hash=hash_password(password),
        is_active=True,
        role=UserRole.TENANT_OWNER,
        tenant_id=tenant.id,
    )
    db.add(user)
    await db.commit()
    await db.refresh(tenant)
    await db.refresh(user)
    return tenant, user


async def change_password(db: AsyncSession, user: User, new_password: str) -> None:
    user.password_hash = hash_password(new_password)
    user.token_version = (user.token_version or 0) + 1
    await db.commit()


async def bump_token_version(db: AsyncSession, user: User) -> None:
    """Logout / parola değişimi sonrası eski tüm token'ları geçersizleştirir."""
    user.token_version = (user.token_version or 0) + 1
    await db.commit()
