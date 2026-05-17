"""Fatura oluşturma — stok düşürme + (borç ise) Debt kaydı açma."""
from dataclasses import dataclass
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


@dataclass
class InvoiceLineInput:
    product_id: UUID
    quantity: Decimal
    product_name: str | None = None
    unit: str | None = None
    unit_price: Decimal | None = None


async def list_invoices(
    db: AsyncSession,
    tenant_id: UUID,
    customer_id: UUID | None = None,
    limit: int = 100,
    offset: int = 0,
    only_order_backed: bool = False,
) -> list[Invoice]:
    stmt = (
        select(Invoice)
        .options(
            selectinload(Invoice.items),
            selectinload(Invoice.customer).selectinload(Customer.account),
            selectinload(Invoice.order),
        )
        .where(Invoice.tenant_id == tenant_id)
        .order_by(Invoice.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    if customer_id:
        stmt = stmt.where(Invoice.customer_id == customer_id)
    if only_order_backed:
        stmt = stmt.where(Invoice.order.has())
    return list((await db.execute(stmt)).scalars().all())


async def get(db: AsyncSession, invoice_id: UUID, tenant_id: UUID) -> Invoice | None:
    stmt = (
        select(Invoice)
        .options(
            selectinload(Invoice.items),
            selectinload(Invoice.customer).selectinload(Customer.account),
            selectinload(Invoice.order),
        )
        .where(Invoice.id == invoice_id, Invoice.tenant_id == tenant_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def _create_from_lines(
    db: AsyncSession,
    *,
    tenant_id: UUID,
    customer_id: UUID,
    payment_method: PaymentMethod,
    cash_amount: Decimal,
    card_amount: Decimal,
    debt_amount: Decimal,
    note: str | None,
    items: list[InvoiceLineInput],
) -> Invoice:
    customer_stmt = select(Customer).where(
        Customer.id == customer_id, Customer.tenant_id == tenant_id
    )
    customer = (await db.execute(customer_stmt)).scalar_one_or_none()
    if not customer:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Müşteri bulunamadı")

    if not items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Sepet boş olamaz")

    product_ids = [item.product_id for item in items]
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
        cash_amount=Decimal("0"),
        card_amount=Decimal("0"),
        debt_amount=Decimal("0"),
        payment_method=payment_method,
        note=note,
    )
    db.add(invoice)
    await db.flush()

    for item_in in items:
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

        unit_price = item_in.unit_price or product.price
        product_name = item_in.product_name or product.name
        unit = item_in.unit or product.unit
        line_total = (unit_price * item_in.quantity).quantize(Decimal("0.01"))

        item = InvoiceItem(
            invoice_id=invoice.id,
            product_id=product.id,
            product_name=product_name,
            unit=unit,
            quantity=item_in.quantity,
            unit_price=unit_price,
            line_total=line_total,
        )
        db.add(item)
        product.stock = product.stock - item_in.quantity
        total += line_total

    invoice.total = total.quantize(Decimal("0.01"))
    cash_amount, card_amount, debt_amount, payment_method = _resolve_payment_split(
        total=invoice.total,
        payment_method=payment_method,
        cash_amount=cash_amount,
        card_amount=card_amount,
        debt_amount=debt_amount,
    )
    invoice.payment_method = payment_method
    invoice.cash_amount = cash_amount
    invoice.card_amount = card_amount
    invoice.debt_amount = debt_amount

    if invoice.debt_amount > 0:
        today = date.today()
        debt = Debt(
            tenant_id=tenant_id,
            invoice_id=invoice.id,
            customer_id=customer.id,
            total_amount=invoice.total,
            paid_amount=(invoice.cash_amount + invoice.card_amount).quantize(Decimal("0.01")),
            issued_on=today,
            due_on=today + timedelta(days=DEBT_DURATION_DAYS),
            status=DebtStatus.GREEN,
        )
        db.add(debt)

    await db.commit()
    return await get(db, invoice.id, tenant_id)  # type: ignore[return-value]


async def create(db: AsyncSession, tenant_id: UUID, data: InvoiceCreate) -> Invoice:
    return await _create_from_lines(
        db,
        tenant_id=tenant_id,
        customer_id=data.customer_id,
        payment_method=data.payment_method,
        cash_amount=data.cash_amount,
        card_amount=data.card_amount,
        debt_amount=data.debt_amount,
        note=data.note,
        items=[
            InvoiceLineInput(product_id=item.product_id, quantity=item.quantity)
            for item in data.items
        ],
    )


async def create_from_order(
    db: AsyncSession,
    *,
    tenant_id: UUID,
    customer_id: UUID,
    payment_method: PaymentMethod,
    cash_amount: Decimal,
    card_amount: Decimal,
    debt_amount: Decimal,
    note: str | None,
    items: list[InvoiceLineInput],
) -> Invoice:
    return await _create_from_lines(
        db,
        tenant_id=tenant_id,
        customer_id=customer_id,
        payment_method=payment_method,
        cash_amount=cash_amount,
        card_amount=card_amount,
        debt_amount=debt_amount,
        note=note,
        items=items,
    )


def _resolve_payment_split(
    *,
    total: Decimal | None,
    payment_method: PaymentMethod,
    cash_amount: Decimal,
    card_amount: Decimal,
    debt_amount: Decimal,
) -> tuple[Decimal, Decimal, Decimal, PaymentMethod]:
    cash_amount = Decimal(cash_amount).quantize(Decimal("0.01"))
    card_amount = Decimal(card_amount).quantize(Decimal("0.01"))
    debt_amount = Decimal(debt_amount).quantize(Decimal("0.01"))

    if cash_amount == 0 and card_amount == 0 and debt_amount == 0:
        if payment_method == PaymentMethod.CASH:
            return total, Decimal("0.00"), Decimal("0.00"), payment_method
        if payment_method == PaymentMethod.CARD:
            return Decimal("0.00"), total, Decimal("0.00"), payment_method
        return Decimal("0.00"), Decimal("0.00"), total, payment_method

    actual_total = (cash_amount + card_amount + debt_amount).quantize(Decimal("0.01"))
    if total is not None and actual_total != total.quantize(Decimal("0.01")):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Ödeme toplamı sipariş toplamı ile eşleşmelidir",
        )

    if debt_amount > 0:
        resolved_method = PaymentMethod.DEBT
    elif card_amount > 0 and cash_amount == 0:
        resolved_method = PaymentMethod.CARD
    else:
        resolved_method = PaymentMethod.CASH

    return cash_amount, card_amount, debt_amount, resolved_method
