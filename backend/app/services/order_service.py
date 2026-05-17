from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.customer import Customer
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.user import User
from app.schemas.order import ConvertOrderToInvoiceRequest, OrderCreate
from app.services import invoice_service


async def list_orders(
    db: AsyncSession,
    *,
    tenant_id: UUID,
    customer_id: UUID | None = None,
    status_filter: OrderStatus | None = None,
) -> list[Order]:
    stmt = (
        select(Order)
        .options(
            selectinload(Order.customer).selectinload(Customer.account),
            selectinload(Order.items),
        )
        .where(Order.tenant_id == tenant_id)
        .order_by(Order.created_at.desc())
    )
    if customer_id is not None:
        stmt = stmt.where(Order.customer_id == customer_id)
    if status_filter is not None:
        stmt = stmt.where(Order.status == status_filter)
    return list((await db.execute(stmt)).scalars().all())


async def get(db: AsyncSession, order_id: UUID, tenant_id: UUID) -> Order | None:
    stmt = (
        select(Order)
        .options(
            selectinload(Order.customer).selectinload(Customer.account),
            selectinload(Order.items),
        )
        .where(Order.id == order_id, Order.tenant_id == tenant_id)
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def create_for_customer(
    db: AsyncSession,
    *,
    customer_user: User,
    data: OrderCreate,
) -> Order:
    if customer_user.tenant_id is None or customer_user.customer_id is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "müşteri hesabı eksik")

    customer_stmt = select(Customer).where(
        Customer.id == customer_user.customer_id,
        Customer.tenant_id == customer_user.tenant_id,
    )
    customer = (await db.execute(customer_stmt)).scalar_one_or_none()
    if customer is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Müşteri bulunamadı")
    if not data.items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Sepet boş olamaz")

    product_ids = [item.product_id for item in data.items]
    products = {
        p.id: p
        for p in (
            await db.execute(
                select(Product).where(
                    Product.id.in_(product_ids),
                    Product.tenant_id == customer_user.tenant_id,
                )
            )
        )
        .scalars()
        .all()
    }

    total = Decimal("0")
    order = Order(
        tenant_id=customer_user.tenant_id,
        customer_id=customer.id,
        created_by_user_id=customer_user.id,
        total=Decimal("0"),
        status=OrderStatus.PENDING,
        note=data.note,
    )
    db.add(order)
    await db.flush()

    for item_in in data.items:
        product = products.get(item_in.product_id)
        if product is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, f"Ürün bulunamadı: {item_in.product_id}"
            )
        line_total = (product.price * item_in.quantity).quantize(Decimal("0.01"))
        db.add(
            OrderItem(
                order_id=order.id,
                product_id=product.id,
                product_name=product.name,
                unit=product.unit,
                quantity=item_in.quantity,
                unit_price=product.price,
                line_total=line_total,
            )
        )
        total += line_total

    order.total = total.quantize(Decimal("0.01"))
    await db.commit()
    return await get(db, order.id, customer_user.tenant_id)  # type: ignore[return-value]


async def convert_to_invoice(
    db: AsyncSession,
    *,
    order: Order,
    payload: ConvertOrderToInvoiceRequest,
) -> Order:
    if order.status != OrderStatus.PENDING:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Sadece bekleyen siparişler faturaya dönüştürülebilir",
        )

    order_total = order.total.quantize(Decimal("0.01"))
    cash_amount = payload.cash_amount.quantize(Decimal("0.01"))
    card_amount = payload.card_amount.quantize(Decimal("0.01"))
    debt_amount = payload.debt_amount.quantize(Decimal("0.01"))
    if cash_amount == 0 and card_amount == 0 and debt_amount == 0:
        method = payload.payment_method or invoice_service.PaymentMethod.CASH
        if method == invoice_service.PaymentMethod.CARD:
            card_amount = order_total
        elif method == invoice_service.PaymentMethod.DEBT:
            debt_amount = order_total
        else:
            cash_amount = order_total

    payment_total = (cash_amount + card_amount + debt_amount).quantize(Decimal("0.01"))
    if payment_total > order_total:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Odeme toplami siparis tutarindan fazla olamaz",
        )
    if payment_total != order_total:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Odeme toplami siparis tutari ile ayni olmali",
        )

    invoice = await invoice_service.create_from_order(
        db,
        tenant_id=order.tenant_id,
        customer_id=order.customer_id,
        payment_method=payload.payment_method or invoice_service.PaymentMethod.CASH,
        cash_amount=cash_amount,
        card_amount=card_amount,
        debt_amount=debt_amount,
        note=payload.note if payload.note is not None else order.note,
        items=[
            invoice_service.InvoiceLineInput(
                product_id=item.product_id,
                quantity=item.quantity,
                product_name=item.product_name,
                unit=item.unit,
                unit_price=item.unit_price,
            )
            for item in order.items
        ],
    )

    refreshed = await get(db, order.id, order.tenant_id)
    if refreshed is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sipariş bulunamadı")
    refreshed.status = OrderStatus.CONVERTED
    refreshed.invoice_id = invoice.id
    await db.commit()
    return await get(db, order.id, order.tenant_id)  # type: ignore[return-value]


async def cancel(db: AsyncSession, *, order: Order) -> Order:
    if order.status != OrderStatus.PENDING:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Sadece bekleyen siparişler iptal edilebilir",
        )
    order.status = OrderStatus.CANCELLED
    await db.commit()
    return await get(db, order.id, order.tenant_id)  # type: ignore[return-value]
