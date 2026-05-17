from pydantic import EmailStr, Field

from app.schemas.common import IDMixin, ORMModel


class CustomerBase(ORMModel):
    name: str = Field(min_length=1, max_length=255)
    phone: str | None = Field(default=None, max_length=32)
    address: str | None = None


class CustomerCreate(CustomerBase):
    account_email: EmailStr | None = None
    account_password: str | None = Field(default=None, min_length=8, max_length=128)
    account_is_active: bool = True


class CustomerUpdate(ORMModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    phone: str | None = Field(default=None, max_length=32)
    address: str | None = None
    account_email: EmailStr | None = None
    account_password: str | None = Field(default=None, min_length=8, max_length=128)
    account_is_active: bool | None = None


class CustomerOut(IDMixin, CustomerBase):
    has_account: bool = False
    account_email: EmailStr | None = None
    account_is_active: bool | None = None
    account_full_name: str | None = None
