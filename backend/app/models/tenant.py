import enum
from datetime import date

from sqlalchemy import Boolean, Date, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPKMixin


class TenantStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    SUSPENDED = "suspended"


class Tenant(Base, UUIDPKMixin, TimestampMixin):
    """İşletme (kiracı) — her işletme kendi ürün/müşteri/borç verisini görür."""

    __tablename__ = "tenants"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    status: Mapped[TenantStatus] = mapped_column(
        Enum(TenantStatus, name="tenant_status", values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=TenantStatus.PENDING,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Manuel takip edilen abonelik bitiş tarihi. None = kontrolsüz.
    # Bu tarih geçtiyse login engellenir, kullanıcıya "süreniz doldu" mesajı görünür.
    paid_until: Mapped[date | None] = mapped_column(Date, nullable=True)
