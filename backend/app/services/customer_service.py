from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.customer import Customer
from app.schemas.customer import CustomerCreate, CustomerUpdate


async def list_all(
    db: AsyncSession, tenant_id: UUID, search: str | None = None
) -> list[Customer]:
    stmt = (
        select(Customer)
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
    return (await db.execute(stmt)).scalar_one_or_none()


async def create(
    db: AsyncSession, tenant_id: UUID, data: CustomerCreate
) -> Customer:
    customer = Customer(tenant_id=tenant_id, **data.model_dump())
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    return customer


async def update(
    db: AsyncSession, customer: Customer, data: CustomerUpdate
) -> Customer:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(customer, field, value)
    await db.commit()
    await db.refresh(customer)
    return customer


async def delete(db: AsyncSession, customer: Customer) -> None:
    await db.delete(customer)
    await db.commit()
