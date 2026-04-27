from datetime import date
from uuid import UUID

from app.schemas.common import MoneyDecimal, ORMModel


class PaymentBreakdown(ORMModel):
    kart: MoneyDecimal
    nakit: MoneyDecimal
    borc: MoneyDecimal


class CategorySales(ORMModel):
    category_id: UUID | None
    category_name: str
    total: MoneyDecimal
    quantity: MoneyDecimal


class TopCustomer(ORMModel):
    customer_id: UUID
    customer_name: str
    total: MoneyDecimal
    invoice_count: int


class DailySales(ORMModel):
    day: date
    total: MoneyDecimal


class ReportSummary(ORMModel):
    from_date: date
    to_date: date
    total_sales: MoneyDecimal
    invoice_count: int
    unique_customers: int
    by_payment: PaymentBreakdown
    outstanding_debt: MoneyDecimal
    overdue_debt: MoneyDecimal
    category_breakdown: list[CategorySales]
    top_customers: list[TopCustomer]
    daily_sales: list[DailySales]
    low_stock_products: int
