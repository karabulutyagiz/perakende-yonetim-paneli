import enum
from decimal import ROUND_HALF_UP, Decimal
from uuid import UUID

from sqlalchemy import Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

_CENT = Decimal("0.01")


class DiscountType(str, enum.Enum):
    """İndirimin nasıl okunacağı: yüzde mi, sabit TL mi."""

    PERCENT = "percent"
    AMOUNT = "amount"


def compute_effective_price(
    price: Decimal,
    discount_type: "DiscountType | None",
    discount_value: Decimal | None,
) -> Decimal:
    """Ürünün indirim uygulanmış satış fiyatı. Negatife düşmez."""
    if discount_type is None or not discount_value or discount_value <= 0:
        return Decimal(price).quantize(_CENT, rounding=ROUND_HALF_UP)

    price = Decimal(price)
    if discount_type == DiscountType.PERCENT:
        pct = min(Decimal(discount_value), Decimal("100"))
        discount = price * pct / Decimal("100")
    else:
        discount = min(Decimal(discount_value), price)

    effective = price - discount
    if effective < 0:
        effective = Decimal("0")
    return effective.quantize(_CENT, rounding=ROUND_HALF_UP)


class Product(Base, UUIDPKMixin, TimestampMixin):
    """Ürün — toptan perakendenin satışa sunduğu kalem."""

    __tablename__ = "products"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    unit: Mapped[str] = mapped_column(String(20), nullable=False)  # adet, kg, lt, koli, ...
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    stock: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False, default=Decimal("0"))
    image_key: Mapped[str | None] = mapped_column(String(512), nullable=True)  # S3 key

    # İndirim ürün kartında tanımlanır; her satışta otomatik uygulanır.
    # discount_type NULL = indirim yok (discount_value o zaman 0 tutulur).
    discount_type: Mapped[DiscountType | None] = mapped_column(
        Enum(DiscountType, name="discount_type", values_callable=lambda x: [e.value for e in x]),
        nullable=True,
    )
    discount_value: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, default=Decimal("0"), server_default="0"
    )

    category_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True
    )
    tenant_id: Mapped[UUID] = mapped_column(
        ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    category: Mapped["Category | None"] = relationship(back_populates="products")  # noqa: F821

    @property
    def effective_price(self) -> Decimal:
        """Müşterinin ödeyeceği birim fiyat (indirim düşülmüş)."""
        return compute_effective_price(self.price, self.discount_type, self.discount_value)

    @property
    def has_discount(self) -> bool:
        return self.effective_price < Decimal(self.price)
