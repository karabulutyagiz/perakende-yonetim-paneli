import enum
from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy import Date, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin


class DebtStatus(str, enum.Enum):
    GREEN = "yesil"        # > 7 gün kaldı
    YELLOW = "sari"        # 4–7 gün kaldı
    RED = "kirmizi"        # 1–3 gün kaldı
    OVERDUE = "gecikti"    # due date geçti
    PAID = "odendi"


class Debt(Base, UUIDPKMixin, TimestampMixin):
    """Borç — borç ile kesilen fatura için oluşturulur. 15 günlük vade."""

    __tablename__ = "debts"

    invoice_id: Mapped[UUID] = mapped_column(
        ForeignKey("invoices.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    customer_id: Mapped[UUID] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    total_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    paid_amount: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), nullable=False, default=Decimal("0")
    )
    issued_on: Mapped[date] = mapped_column(Date, nullable=False)
    due_on: Mapped[date] = mapped_column(Date, nullable=False)  # issued_on + 15 gün
    status: Mapped[DebtStatus] = mapped_column(
        Enum(DebtStatus, name="debt_status", values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=DebtStatus.GREEN,
    )

    invoice: Mapped["Invoice"] = relationship(back_populates="debt")  # noqa: F821
    customer: Mapped["Customer"] = relationship()  # noqa: F821
    payments: Mapped[list["DebtPayment"]] = relationship(
        back_populates="debt", cascade="all, delete-orphan", order_by="DebtPayment.paid_on.desc()"
    )

    @property
    def remaining(self) -> Decimal:
        return (self.total_amount or Decimal("0")) - (self.paid_amount or Decimal("0"))


class DebtPayment(Base, UUIDPKMixin, TimestampMixin):
    """Borç ödeme kaydı — kısmi ödemeler desteklenir."""

    __tablename__ = "debt_payments"

    debt_id: Mapped[UUID] = mapped_column(
        ForeignKey("debts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    paid_on: Mapped[date] = mapped_column(Date, nullable=False)

    debt: Mapped["Debt"] = relationship(back_populates="payments")
