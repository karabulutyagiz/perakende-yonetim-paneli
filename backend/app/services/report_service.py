"""Rapor / dashboard hesaplamaları."""
from datetime import date, timedelta
from decimal import Decimal
from uuid import UUID

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.models.customer import Customer
from app.models.debt import Debt, DebtStatus
from app.models.invoice import Invoice, InvoiceItem, PaymentMethod
from app.models.product import Product
from app.schemas.report import (
    CategorySales,
    DailySales,
    PaymentBreakdown,
    ReportSummary,
    TopCustomer,
)

LOW_STOCK_THRESHOLD = Decimal("5")


async def build_summary(
    db: AsyncSession,
    tenant_id: UUID,
    from_date: date | None,
    to_date: date | None,
) -> ReportSummary:
    to_date = to_date or date.today()
    from_date = from_date or (to_date - timedelta(days=30))

    range_filter = and_(
        func.date(Invoice.created_at) >= from_date,
        func.date(Invoice.created_at) <= to_date,
        Invoice.tenant_id == tenant_id,
    )

    # Toplam satış + fatura sayısı + tekil müşteri
    head = (
        await db.execute(
            select(
                func.coalesce(func.sum(Invoice.total), 0),
                func.count(Invoice.id),
                func.count(func.distinct(Invoice.customer_id)),
            ).where(range_filter)
        )
    ).one()
    total_sales = Decimal(head[0] or 0)
    invoice_count = int(head[1] or 0)
    unique_customers = int(head[2] or 0)

    # Ödeme yöntemi kırılımı
    pay_rows = (
        await db.execute(
            select(Invoice.payment_method, func.coalesce(func.sum(Invoice.total), 0))
            .where(range_filter)
            .group_by(Invoice.payment_method)
        )
    ).all()
    pay_map = {method: Decimal(total or 0) for method, total in pay_rows}
    by_payment = PaymentBreakdown(
        kart=pay_map.get(PaymentMethod.CARD, Decimal("0")),
        nakit=pay_map.get(PaymentMethod.CASH, Decimal("0")),
        borc=pay_map.get(PaymentMethod.DEBT, Decimal("0")),
    )

    # Açık ve geciken borçlar (tarih filtresiz — güncel durum)
    debt_head = (
        await db.execute(
            select(
                func.coalesce(func.sum(Debt.total_amount - Debt.paid_amount), 0),
                func.coalesce(
                    func.sum(
                        Debt.total_amount - Debt.paid_amount,
                    ).filter(Debt.status == DebtStatus.OVERDUE),
                    0,
                ),
            ).where(Debt.status != DebtStatus.PAID, Debt.tenant_id == tenant_id)
        )
    ).one()
    outstanding_debt = Decimal(debt_head[0] or 0)
    overdue_debt = Decimal(debt_head[1] or 0)

    # Kategori kırılımı
    cat_rows = (
        await db.execute(
            select(
                Category.id,
                Category.name,
                func.coalesce(func.sum(InvoiceItem.line_total), 0),
                func.coalesce(func.sum(InvoiceItem.quantity), 0),
            )
            .select_from(InvoiceItem)
            .join(Invoice, Invoice.id == InvoiceItem.invoice_id)
            .join(Product, Product.id == InvoiceItem.product_id)
            .join(Category, Category.id == Product.category_id, isouter=True)
            .where(range_filter)
            .group_by(Category.id, Category.name)
            .order_by(func.sum(InvoiceItem.line_total).desc())
        )
    ).all()
    category_breakdown = [
        CategorySales(
            category_id=cid,
            category_name=cname or "Kategorisiz",
            total=Decimal(total or 0),
            quantity=Decimal(qty or 0),
        )
        for cid, cname, total, qty in cat_rows
    ]

    # En çok satılan müşteriler
    cust_rows = (
        await db.execute(
            select(
                Customer.id,
                Customer.name,
                func.coalesce(func.sum(Invoice.total), 0),
                func.count(Invoice.id),
            )
            .join(Invoice, Invoice.customer_id == Customer.id)
            .where(range_filter)
            .group_by(Customer.id, Customer.name)
            .order_by(func.sum(Invoice.total).desc())
            .limit(10)
        )
    ).all()
    top_customers = [
        TopCustomer(
            customer_id=cid,
            customer_name=cname,
            total=Decimal(total or 0),
            invoice_count=int(cnt or 0),
        )
        for cid, cname, total, cnt in cust_rows
    ]

    # Günlük satış
    daily_rows = (
        await db.execute(
            select(
                func.date(Invoice.created_at).label("day"),
                func.coalesce(func.sum(Invoice.total), 0),
            )
            .where(range_filter)
            .group_by("day")
            .order_by("day")
        )
    ).all()
    daily_sales = [DailySales(day=day, total=Decimal(total or 0)) for day, total in daily_rows]

    # Düşük stok ürün sayısı
    low_stock = (
        await db.execute(
            select(func.count(Product.id)).where(
                Product.stock <= LOW_STOCK_THRESHOLD,
                Product.tenant_id == tenant_id,
            )
        )
    ).scalar_one()

    return ReportSummary(
        from_date=from_date,
        to_date=to_date,
        total_sales=total_sales,
        invoice_count=invoice_count,
        unique_customers=unique_customers,
        by_payment=by_payment,
        outstanding_debt=outstanding_debt,
        overdue_debt=overdue_debt,
        category_breakdown=category_breakdown,
        top_customers=top_customers,
        daily_sales=daily_sales,
        low_stock_products=int(low_stock or 0),
    )
