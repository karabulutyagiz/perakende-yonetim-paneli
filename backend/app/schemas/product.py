from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.schemas.category import CategoryOut
from app.schemas.common import IDMixin, MoneyDecimal, ORMModel


class ProductBase(ORMModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None
    unit: str = Field(min_length=1, max_length=20)
    price: MoneyDecimal = Field(ge=Decimal("0"))
    stock: MoneyDecimal = Field(ge=Decimal("0"))
    category_id: UUID | None = None
    image_key: str | None = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(ORMModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    unit: str | None = Field(default=None, min_length=1, max_length=20)
    price: MoneyDecimal | None = Field(default=None, ge=Decimal("0"))
    stock: MoneyDecimal | None = Field(default=None, ge=Decimal("0"))
    category_id: UUID | None = None
    image_key: str | None = None


class ProductOut(IDMixin, ProductBase):
    image_url: str | None = None
    category: CategoryOut | None = None


class PresignUploadRequest(ORMModel):
    filename: str = Field(min_length=1, max_length=255)
    content_type: str = Field(min_length=1, max_length=100)


class PresignUploadResponse(ORMModel):
    upload_url: str
    key: str
    fields: dict[str, str] = {}
