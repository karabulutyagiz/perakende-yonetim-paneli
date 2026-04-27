"""Fatura oluşturma — stok düşürme + (borç ise) Debt kaydı açma."""
from datetime import date, timedelta
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.customer import Customer
from app.models.debt import Debt, DebtStatus
from app.models.invoice import Invoice, InvoiceItem, PaymentMethod
from app.models.product import Product
from app.schemas.invoice import InvoiceCreate

DEBT_DURATION_DAYS = 15


async def list_invoices(
    db: AsyncSession,
    tenant_id: UUID,
    customer_id: UUID | None = None,
    limit: int = 100,
    offset: int = 0,
) -> list[Invoice]:
    stmt = (
        select(Invoice)
        .options(selectinload(Invoice.items), selectinload(Invoice.customer))
        .where(Invoice.tenant_id == tenant_id)
        .order_by(Invoice.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    if customer_id:
        stmt = stmt.where(Invoice.customer_id == customer_id)
    return list((await db.execute(stmt)).scalars().all())


async def get(db: AsyncSession, invoice_id: UUID, tenant_id: UUID) -> Invoice | None:
    stmt = (
        select(Invoice)
        .options(selectinload(Invoice.items), selectinload(Invoice.customer))
        .where(Invoice.id == invoice_id, Invoice.tenant_id == tenant_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def create(db: AsyncSession, tenant_id: UUID, data: InvoiceCreate) -> Invoice:
    # Müşteri aynı tenant'a mı ait?
    customer_stmt = select(Customer).where(
        Customer.id == data.customer_id, Customer.tenant_id == tenant_id
    )
    customer = (await db.execute(customer_stmt)).scalar_one_or_none()
    if not customer:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Müşteri bulunamadı")

    if not data.items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Sepet boş olamaz")

    product_ids = [item.product_id for item in data.items]
    products = {
        p.id: p
        for p in (
            await db.execute(
                select(Product)
                .where(
                    Product.id.in_(product_ids),
                    Product.tenant_id == tenant_id,
                )
                .with_for_update()
            )
        )
        .scalars()
        .all()
    }

    total = Decimal("0")
    invoice = Invoice(
        tenant_id=tenant_id,
        customer_id=customer.id,
        total=Decimal("0"),
        payment_method=data.payment_method,
        note=data.note,
    )
    db.add(invoice)
    await db.flush()

    for item_in in data.items:
        product = products.get(item_in.product_id)
        if not product:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, f"Ürün bulunamadı: {item_in.product_id}"
            )
        if product.stock < item_in.quantity:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"Yetersiz stok: {product.name} (mevcut {product.stock} {product.unit})",
            )
        line_total = (product.price * item_in.quantity).quantize(Decimal("0.01"))
        item = InvoiceItem(
            invoice_id=invoice.id,
            product_id=product.id,
            product_name=product.name,
            unit=product.unit,
            quantity=item_in.quantity,
            unit_price=product.price,
            line_total=line_total,
        )
        db.add(item)
        product.stock = product.stock - item_in.quantity
        total += line_total

    invoice.total = total.quantize(Decimal("0.01"))

    if data.payment_method == PaymentMethod.DEBT:
        today = date.today()
        debt = Debt(
            tenant_id=tenant_id,
            invoice_id=invoice.id,
            customer_id=customer.id,
            total_amount=invoice.total,
            paid_amount=Decimal("0"),
            issued_on=today,
            due_on=today + timedelta(days=DEBT_DURATION_DAYS),
            status=DebtStatus.GREEN,
        )
        db.add(debt)

    await db.commit()
    return await get(db, invoice.id, tenant_id)  # type: ignore[return-value]
