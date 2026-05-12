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
