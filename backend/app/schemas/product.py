from decimal import Decimal
from uuid import UUID

from pydantic import Field, model_validator

from app.models.product import DiscountType, compute_effective_price
from app.schemas.category import CategoryOut
from app.schemas.common import IDMixin, MoneyDecimal, ORMModel


def validate_discount(
    price: Decimal,
    discount_type: DiscountType | None,
    discount_value: Decimal,
) -> None:
    """İndirim tanımı tutarlı mı? Değilse ValueError fırlatır."""
    if discount_type is None:
        return
    if discount_value <= 0:
        raise ValueError("İndirim değeri 0'dan büyük olmalı")
    if discount_type == DiscountType.PERCENT:
        if discount_value > 100:
            raise ValueError("Yüzde indirim 100'den büyük olamaz")
    elif discount_value > price:
        raise ValueError("TL indirimi ürün fiyatından büyük olamaz")


class ProductBase(ORMModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None
    unit: str = Field(min_length=1, max_length=20)
    price: MoneyDecimal = Field(ge=Decimal("0"))
    stock: MoneyDecimal = Field(ge=Decimal("0"))
    category_id: UUID | None = None
    image_key: str | None = None
    # İndirim: type None ise indirim yok, value 0'a çekilir.
    discount_type: DiscountType | None = None
    discount_value: MoneyDecimal = Field(default=Decimal("0"), ge=Decimal("0"))


class ProductCreate(ProductBase):
    @model_validator(mode="after")
    def _check_discount(self) -> "ProductCreate":
        if self.discount_type is None:
            self.discount_value = Decimal("0")
        else:
            validate_discount(self.price, self.discount_type, self.discount_value)
        return self


class ProductUpdate(ORMModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    unit: str | None = Field(default=None, min_length=1, max_length=20)
    price: MoneyDecimal | None = Field(default=None, ge=Decimal("0"))
    stock: MoneyDecimal | None = Field(default=None, ge=Decimal("0"))
    category_id: UUID | None = None
    image_key: str | None = None
    # Kısmi güncelleme: indirim doğrulaması birleşmiş hâl üzerinde
    # product_service.update() içinde yapılır.
    discount_type: DiscountType | None = None
    discount_value: MoneyDecimal | None = Field(default=None, ge=Decimal("0"))


class ProductOut(IDMixin, ProductBase):
    image_url: str | None = None
    category: CategoryOut | None = None
    # İstemcinin gösterdiği/sattığı fiyat — indirim düşülmüş hâli.
    effective_price: MoneyDecimal = Decimal("0")

    @model_validator(mode="after")
    def _fill_effective_price(self) -> "ProductOut":
        self.effective_price = compute_effective_price(
            self.price, self.discount_type, self.discount_value
        )
        return self


class PresignUploadRequest(ORMModel):
    filename: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=100)


class PresignUploadResponse(ORMModel):
    upload_url: str
    key: str
    fields: dict[str, str] = {}
