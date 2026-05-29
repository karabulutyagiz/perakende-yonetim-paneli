from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.customer import Customer
from app.schemas.customer import CustomerCreate, CustomerUpdate
from app.services import user_service


async def list_all(
    db: AsyncSession, tenant_id: UUID, search: str | None = None
) -> list[Customer]:
    stmt = (
        select(Customer)
        .options(selectinload(Customer.account))
        .where(Customer.tenant_id == tenant_id)
        .order_by(Customer.name)
    )
    if search:
        stmt = stmt.where(Customer.name.ilike(f"%{search.strip()}%"))
    return list((await db.execute(stmt)).scalars().all())


async def get(
    db: AsyncSession, customer_id: UUID, tenant_id: UUID
) -> Customer | None:
    stmt = select(Customer).where(
        Customer.id == customer_id, Customer.tenant_id == tenant_id
    )
    stmt = stmt.options(selectinload(Customer.account))
    return (await db.execute(stmt)).scalar_one_or_none()


async def create(
    db: AsyncSession, tenant_id: UUID, data: CustomerCreate
) -> Customer:
    payload = data.model_dump(
        exclude={"account_email", "account_password", "account_is_active"}
    )
    customer = Customer(tenant_id=tenant_id, **payload)
    db.add(customer)
    await db.flush()

    if data.account_email is not None:
        existing = await user_service.get_by_email(db, data.account_email)
        if existing is not None:
            raise ValueError("Bu e-posta ile kayıt zaten var")
        if not data.account_password:
            raise ValueError("Müşteri hesabı için parola gerekli")
        await user_service.create_customer_user(
            db,
            tenant_id=tenant_id,
            customer=customer,
            email=data.account_email,
            password=data.account_password,
            is_active=data.account_is_active,
        )

    await db.commit()
    return await get(db, customer.id, tenant_id)  # type: ignore[return-value]


async def update(
    db: AsyncSession, customer: Customer, data: CustomerUpdate
) -> Customer:
    updates = data.model_dump(exclude_unset=True)
    account_email = updates.pop("account_email", None)
    account_password = updates.pop("account_password", None)
    account_is_active = updates.pop("account_is_active", None)

    for field, value in updates.items():
        setattr(customer, field, value)

    account_updates_requested = any(
        key in data.model_fields_set
        for key in {"account_email", "account_password", "account_is_active"}
    )
    if account_updates_requested:
        account = customer.account
        if account is None:
            if not account_email or not account_password:
                raise ValueError("Yeni müşteri hesabı için e-posta ve parola gerekli")
            existing = await user_service.get_by_email(db, account_email)
            if existing is not None:
                raise ValueError("Bu e-posta ile kayıt zaten var")
            account = await user_service.create_customer_user(
                db,
                tenant_id=customer.tenant_id,
                customer=customer,
                email=account_email,
                password=account_password,
                is_active=True if account_is_active is None else account_is_active,
            )
        else:
            if account_email is not None and account_email.lower() != account.email:
                existing = await user_service.get_by_email(db, account_email)
                if existing is not None and existing.id != account.id:
                    raise ValueError("Bu e-posta ile kayıt zaten var")
                account.email = account_email.lower()
            if account_password is not None:
                account.password_hash = user_service.hash_password(account_password)
            if account_is_active is not None:
                account.is_active = account_is_active
            account.full_name = customer.name

    await db.commit()
    return await get(db, customer.id, customer.tenant_id)  # type: ignore[return-value]


async def delete(db: AsyncSession, customer: Customer) -> None:
    await db.delete(customer)
    await db.commit()
