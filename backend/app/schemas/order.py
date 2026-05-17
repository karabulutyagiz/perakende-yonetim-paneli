from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.models.invoice import PaymentMethod
from app.models.order import OrderStatus
from app.schemas.common import IDMixin, MoneyDecimal, ORMModel
from app.schemas.customer import CustomerOut


class OrderItemCreate(ORMModel):
    product_id: UUID
    quantity: MoneyDecimal = Field(gt=0)


class OrderCreate(ORMModel):
    items: list[OrderItemCreate] = Field(min_length=1)
    note: str | None = Field(default=None, max_length=500)


class ConvertOrderToInvoiceRequest(ORMModel):
    payment_method: PaymentMethod | None = None
    cash_amount: MoneyDecimal = Field(default=Decimal("0"), ge=Decimal("0"))
    card_amount: MoneyDecimal = Field(default=Decimal("0"), ge=Decimal("0"))
    debt_amount: MoneyDecimal = Field(default=Decimal("0"), ge=Decimal("0"))
    note: str | None = Field(default=None, max_length=500)


class OrderItemOut(IDMixin):
    product_id: UUID
    product_name: str
    unit: str
    quantity: MoneyDecimal
    unit_price: MoneyDecimal
    line_total: MoneyDecimal


class OrderOut(IDMixin):
    order_number: str
    customer_id: UUID
    created_by_user_id: UUID
    invoice_id: UUID | None = None
    total: MoneyDecimal
    status: OrderStatus
    note: str | None = None
    customer: CustomerOut | None = None
    items: list[OrderItemOut] = []
