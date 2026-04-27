from pydantic import Field

from app.schemas.common import IDMixin, ORMModel


class CustomerBase(ORMModel):
    name: str = Field(min_length=1, max_length=255)
    phone: str | None = Field(default=None, max_length=32)
    address: str | None = None


class CustomerCreate(CustomerBase):
    pass


class CustomerUpdate(ORMModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    phone: str | None = Field(default=None, max_length=32)
    address: str | None = None


class CustomerOut(IDMixin, CustomerBase):
    pass
