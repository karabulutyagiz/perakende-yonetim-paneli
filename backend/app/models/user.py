import enum
from uuid import UUID

from sqlalchemy import Boolean, Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin


class UserRole(str, enum.Enum):
    PLATFORM_OWNER = "platform_owner"  # tenant_id = NULL; tüm tenantları yönetir
    TENANT_OWNER = "tenant_owner"      # bir tenant'a ait işletme sahibi
    CUSTOMER = "customer"              # bir tenant içindeki müşteri hesabı


class User(Base, UUIDPKMixin, TimestampMixin):
    """Kullanıcı. Tek tenant'a ait (veya platform_owner ise tenant_id = NULL)."""

    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("tenant_id", "email", name="uq_users_tenant_email"),
    )

    email: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Logout / parola değişimi bu değeri artırır; eski access + refresh token'lar geçersiz olur.
    token_version: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=UserRole.TENANT_OWNER,
    )
    tenant_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), nullable=True, index=True
    )
    customer_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("customers.id", ondelete="CASCADE"), nullable=True, index=True
    )

    tenant: Mapped["Tenant | None"] = relationship()  # noqa: F821
    customer: Mapped["Customer | None"] = relationship(back_populates="account")  # noqa: F821
