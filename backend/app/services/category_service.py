from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate


async def list_all(db: AsyncSession, tenant_id: UUID) -> list[Category]:
    result = await db.execute(
        select(Category).where(Category.tenant_id == tenant_id).order_by(Category.name)
    )
    return list(result.scalars().all())


async def get(
    db: AsyncSession, category_id: UUID, tenant_id: UUID
) -> Category | None:
    stmt = select(Category).where(
        Category.id == category_id, Category.tenant_id == tenant_id
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def create(
    db: AsyncSession, tenant_id: UUID, data: CategoryCreate
) -> Category:
    category = Category(name=data.name.strip(), tenant_id=tenant_id)
    db.add(category)
    await db.commit()
    await db.refresh(category)
    return category


async def update(
    db: AsyncSession, category: Category, data: CategoryUpdate
) -> Category:
    if data.name is not None:
        category.name = data.name.strip()
    await db.commit()
    await db.refresh(category)
    return category


async def delete(db: AsyncSession, category: Category) -> None:
    await db.delete(category)
    await db.commit()
