from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.models.invoice import PaymentMethod
from app.schemas.common import IDMixin, MoneyDecimal, ORMModel
from app.schemas.customer import CustomerOut


class CartItemIn(ORMModel):
    product_id: UUID
    quantity: MoneyDecimal = Field(gt=Decimal("0"))


class InvoiceCreate(ORMModel):
    customer_id: UUID
    payment_method: PaymentMethod
    items: list[CartItemIn] = Field(min_length=1)
    note: str | None = Field(default=None, max_length=500)


class InvoiceItemOut(IDMixin):
    product_id: UUID
    product_name: str
    unit: str
    quantity: MoneyDecimal
    unit_price: MoneyDecimal
    line_total: MoneyDecimal


class InvoiceOut(IDMixin):
    customer_id: UUID
    total: MoneyDecimal
    payment_method: PaymentMethod
    note: str | None
    customer: CustomerOut | None = None
    items: list[InvoiceItemOut] = []
