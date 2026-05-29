"""Rapor / dashboard hesaplamaları."""
from datetime import date, timedelta
from decimal import Decimal
from uuid import UUID

from sqlalchemy import and_, extract, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.models.customer import Customer
from app.models.debt import Debt, DebtStatus
from app.models.invoice import Invoice, InvoiceItem
from app.models.product import Product
from app.schemas.report import (
    CategorySales,
    CustomerProductStat,
    DailySales,
    MonthlySales,
    PaymentBreakdown,
    ProductCustomerStat,
    ReportSummary,
    TopCustomer,
    TopProduct,
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
    by_payment = PaymentBreakdown(
        kart=Decimal(
            (
                await db.execute(
                    select(func.coalesce(func.sum(Invoice.card_amount), 0)).where(range_filter)
                )
            ).scalar_one()
            or 0
        ),
        nakit=Decimal(
            (
                await db.execute(
                    select(func.coalesce(func.sum(Invoice.cash_amount), 0)).where(range_filter)
                )
            ).scalar_one()
            or 0
        ),
        borc=Decimal(
            (
                await db.execute(
                    select(func.coalesce(func.sum(Invoice.debt_amount), 0)).where(range_filter)
                )
            ).scalar_one()
            or 0
        ),
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

    # En çok satılan ürünler — top 20
    prod_rows = (
        await db.execute(
            select(
                Product.id,
                InvoiceItem.product_name,
                InvoiceItem.unit,
                func.coalesce(func.sum(InvoiceItem.line_total), 0),
                func.coalesce(func.sum(InvoiceItem.quantity), 0),
            )
            .select_from(InvoiceItem)
            .join(Invoice, Invoice.id == InvoiceItem.invoice_id)
            .join(Product, Product.id == InvoiceItem.product_id)
            .where(range_filter)
            .group_by(Product.id, InvoiceItem.product_name, InvoiceItem.unit)
            .order_by(func.sum(InvoiceItem.line_total).desc())
            .limit(20)
        )
    ).all()
    top_products = [
        TopProduct(
            product_id=pid,
            product_name=pname,
            unit=unit,
            total_revenue=Decimal(total or 0),
            quantity_sold=Decimal(qty or 0),
        )
        for pid, pname, unit, total, qty in prod_rows
    ]

    # Aylık satış (tüm zamanlardan — genel trend için)
    year_col = extract("year", Invoice.created_at)
    month_col = extract("month", Invoice.created_at)
    month_rows = (
        await db.execute(
            select(
                year_col.label("y"),
                month_col.label("m"),
                func.coalesce(func.sum(Invoice.total), 0),
                func.count(Invoice.id),
            )
            .where(Invoice.tenant_id == tenant_id)
            .group_by("y", "m")
            .order_by("y", "m")
        )
    ).all()
    monthly_sales = [
        MonthlySales(
            month=f"{int(y):04d}-{int(m):02d}",
            total=Decimal(total or 0),
            invoice_count=int(cnt or 0),
        )
        for y, m, total, cnt in month_rows
    ]

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
        top_products=top_products,
        daily_sales=daily_sales,
        monthly_sales=monthly_sales,
        low_stock_products=int(low_stock or 0),
    )


async def top_customers_for_product(
    db: AsyncSession, tenant_id: UUID, product_id: UUID, limit: int = 10
) -> list[ProductCustomerStat]:
    """Verilen ürünü en çok alan müşteriler — toplam miktar ve ciroya göre."""
    rows = (
        await db.execute(
            select(
                Customer.id,
                Customer.name,
                func.coalesce(func.sum(InvoiceItem.quantity), 0),
                func.coalesce(func.sum(InvoiceItem.line_total), 0),
            )
            .select_from(InvoiceItem)
            .join(Invoice, Invoice.id == InvoiceItem.invoice_id)
            .join(Customer, Customer.id == Invoice.customer_id)
            .where(
                InvoiceItem.product_id == product_id,
                Invoice.tenant_id == tenant_id,
            )
            .group_by(Customer.id, Customer.name)
            .order_by(func.sum(InvoiceItem.line_total).desc())
            .limit(limit)
        )
    ).all()
    return [
        ProductCustomerStat(
            customer_id=cid,
            customer_name=cname,
            quantity=Decimal(qty or 0),
            total=Decimal(total or 0),
        )
        for cid, cname, qty, total in rows
    ]


async def top_products_for_customer(
    db: AsyncSession, tenant_id: UUID, customer_id: UUID, limit: int = 10
) -> list[CustomerProductStat]:
    """Verilen müşterinin en çok aldığı ürünler — toplam miktar ve ciroya göre."""
    rows = (
        await db.execute(
            select(
                Product.id,
                InvoiceItem.product_name,
                InvoiceItem.unit,
                func.coalesce(func.sum(InvoiceItem.quantity), 0),
                func.coalesce(func.sum(InvoiceItem.line_total), 0),
            )
            .select_from(InvoiceItem)
            .join(Invoice, Invoice.id == InvoiceItem.invoice_id)
            .join(Product, Product.id == InvoiceItem.product_id)
            .where(
                Invoice.customer_id == customer_id,
                Invoice.tenant_id == tenant_id,
            )
            .group_by(Product.id, InvoiceItem.product_name, InvoiceItem.unit)
            .order_by(func.sum(InvoiceItem.line_total).desc())
            .limit(limit)
        )
    ).all()
    return [
        CustomerProductStat(
            product_id=pid,
            product_name=pname,
            unit=unit,
            quantity=Decimal(qty or 0),
            total=Decimal(total or 0),
        )
        for pid, pname, unit, qty, total in rows
    ]
