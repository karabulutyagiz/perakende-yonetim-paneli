from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate


async def list_products(
    db: AsyncSession,
    tenant_id: UUID,
    search: str | None = None,
    category_id: UUID | None = None,
    limit: int = 200,
    offset: int = 0,
) -> list[Product]:
    stmt = (
        select(Product)
        .options(selectinload(Product.category))
        .where(Product.tenant_id == tenant_id)
        .order_by(Product.name)
    )
    if search:
        like = f"%{search.strip()}%"
        stmt = stmt.where(or_(Product.name.ilike(like), Product.description.ilike(like)))
    if category_id:
        stmt = stmt.where(Product.category_id == category_id)
    stmt = stmt.limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get(
    db: AsyncSession, product_id: UUID, tenant_id: UUID
) -> Product | None:
    stmt = (
        select(Product)
        .options(selectinload(Product.category))
        .where(Product.id == product_id, Product.tenant_id == tenant_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def create(
    db: AsyncSession, tenant_id: UUID, data: ProductCreate
) -> Product:
    product = Product(tenant_id=tenant_id, **data.model_dump())
    db.add(product)
    await db.commit()
    return await get(db, product.id, tenant_id)  # type: ignore[return-value]


async def update(
    db: AsyncSession, product: Product, data: ProductUpdate
) -> Product:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    await db.commit()
    return await get(db, product.id, product.tenant_id)  # type: ignore[return-value]


async def delete(db: AsyncSession, product: Product) -> None:
    await db.delete(product)
    await db.commit()
