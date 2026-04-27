from pydantic import Field

from app.schemas.common import IDMixin, ORMModel


class CategoryCreate(ORMModel):
    name: str = Field(min_length=1, max_length=120)


class CategoryUpdate(ORMModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)


class CategoryOut(IDMixin):
    name: str
