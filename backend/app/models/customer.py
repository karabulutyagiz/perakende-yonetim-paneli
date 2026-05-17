from uuid import UUID

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin


class Customer(Base, UUIDPKMixin, TimestampMixin):
    """Müşteri — admin panelinden manuel eklenir."""

    __tablename__ = "customers"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True
    )

    invoices: Mapped[list["Invoice"]] = relationship(  # noqa: F821
        back_populates="customer", cascade="all, delete-orphan"
    )
    account: Mapped["User | None"] = relationship(  # noqa: F821
        back_populates="customer", uselist=False, cascade="all, delete-orphan"
    )
    orders: Mapped[list["Order"]] = relationship(  # noqa: F821
        back_populates="customer", cascade="all, delete-orphan"
    )

    @property
    def has_account(self) -> bool:
        return self.account is not None

    @property
    def account_email(self) -> str | None:
        return self.account.email if self.account is not None else None

    @property
    def account_is_active(self) -> bool | None:
        return self.account.is_active if self.account is not None else None

    @property
    def account_full_name(self) -> str | None:
        return self.account.full_name if self.account is not None else None
