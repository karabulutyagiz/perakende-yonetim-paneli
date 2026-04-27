from datetime import date
from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.models.debt import DebtStatus
from app.schemas.common import IDMixin, MoneyDecimal, ORMModel
from app.schemas.customer import CustomerOut


class DebtPaymentCreate(ORMModel):
    debt_id: UUID | None = None  # boşsa customer'ın en eski borcundan başlayarak dağıtılır
    customer_id: UUID | None = None
    amount: MoneyDecimal = Field(gt=Decimal("0"))
    paid_on: date | None = None


class DebtPaymentOut(IDMixin):
    debt_id: UUID
    amount: MoneyDecimal
    paid_on: date


class DebtOut(IDMixin):
    invoice_id: UUID
    customer_id: UUID
    total_amount: MoneyDecimal
    paid_amount: MoneyDecimal
    remaining: MoneyDecimal
    issued_on: date
    due_on: date
    days_left: int  # negatif olabilir (gecikti)
    status: DebtStatus
    customer: CustomerOut | None = None


class CustomerDebtSummary(ORMModel):
    customer: CustomerOut
    total_debt: MoneyDecimal
    total_paid: MoneyDecimal
    remaining: MoneyDecimal
    debts_count: int
