from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import hash_password, needs_rehash, verify_password
from app.models.category import Category
from app.models.customer import Customer
from app.models.debt import Debt, DebtPayment
from app.models.invoice import Invoice, InvoiceItem
from app.models.order import Order, OrderItem
from app.models.product import Product
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
    full_name: str | None = None,
) -> User:
    user = User(
        email=email.lower(),
        full_name=full_name or customer.name,
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
    """Yeni işletme + sahibi kayıt eder. Tenant `approved` statüsünde açılır;
    public B2B SaaS akışında (Apple Guideline 3.2) kaydolan kullanıcı uygulamayı
    anında tam olarak kullanabilmelidir. Kötüye kullanım olursa platform_owner
    sonradan tenant'ı `suspended` yapabilir."""
    tenant = Tenant(
        name=business_name,
        contact_email=email.lower(),
        contact_phone=contact_phone,
        status=TenantStatus.APPROVED,
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


async def delete_tenant_cascade(db: AsyncSession, tenant_id: UUID) -> None:
    """Tenant'a bağlı tüm operasyonel veriyi RESTRICT FK'lere takılmayacak
    sırada manuel siler, sonra tenant'ı düşürür.

    invoice.customer_id ve debt.customer_id RESTRICT olduğu için
    tenant CASCADE'i tek başına yetmez."""
    # Önce ödeme/borç (debts → debt_payments CASCADE)
    await db.execute(delete(DebtPayment).where(
        DebtPayment.debt_id.in_(select(Debt.id).where(Debt.tenant_id == tenant_id))
    ))
    await db.execute(delete(Debt).where(Debt.tenant_id == tenant_id))
    # Fatura kalemleri → fatura
    await db.execute(delete(InvoiceItem).where(
        InvoiceItem.invoice_id.in_(select(Invoice.id).where(Invoice.tenant_id == tenant_id))
    ))
    await db.execute(delete(Invoice).where(Invoice.tenant_id == tenant_id))
    # Sipariş kalemleri → sipariş
    await db.execute(delete(OrderItem).where(
        OrderItem.order_id.in_(select(Order.id).where(Order.tenant_id == tenant_id))
    ))
    await db.execute(delete(Order).where(Order.tenant_id == tenant_id))
    # Ürünler, kategoriler, müşteriler (artık FK referansı kalmadı)
    await db.execute(delete(Product).where(Product.tenant_id == tenant_id))
    await db.execute(delete(Category).where(Category.tenant_id == tenant_id))
    await db.execute(delete(Customer).where(Customer.tenant_id == tenant_id))
    # Kullanıcılar (tenant_owner + customer hesapları)
    await db.execute(delete(User).where(User.tenant_id == tenant_id))
    # Son: tenant
    await db.execute(delete(Tenant).where(Tenant.id == tenant_id))
    await db.commit()


async def delete_customer_account(db: AsyncSession, user: User) -> None:
    """CUSTOMER rolü için: sadece kullanıcının login satırını siler.
    Müşteri kaydı (Customer) tenant_owner'ın CRM verisi olduğu için tenant'ta kalır."""
    await db.execute(delete(User).where(User.id == user.id))
    await db.commit()
