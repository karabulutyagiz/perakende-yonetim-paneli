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


class TopProduct(ORMModel):
    product_id: UUID
    product_name: str
    unit: str
    total_revenue: MoneyDecimal
    quantity_sold: MoneyDecimal


class ProductCustomerStat(ORMModel):
    customer_id: UUID
    customer_name: str
    quantity: MoneyDecimal
    total: MoneyDecimal


class CustomerProductStat(ORMModel):
    product_id: UUID
    product_name: str
    unit: str
    quantity: MoneyDecimal
    total: MoneyDecimal


class DailySales(ORMModel):
    day: date
    total: MoneyDecimal


class MonthlySales(ORMModel):
    month: str  # "YYYY-MM"
    total: MoneyDecimal
    invoice_count: int


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
    top_products: list[TopProduct]
    daily_sales: list[DailySales]
    monthly_sales: list[MonthlySales]
    low_stock_products: int
