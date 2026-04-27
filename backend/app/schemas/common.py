from datetime import datetime
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, PlainSerializer

# Decimal alanlarını JSON'a float olarak yazan tip.
# Flutter/JS tarafında num olarak gelir, string cast hataları olmaz.
MoneyDecimal = Annotated[Decimal, PlainSerializer(lambda v: float(v), return_type=float, when_used="json")]


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class IDMixin(ORMModel):
    id: UUID
    created_at: datetime
    updated_at: datetime


class Page(ORMModel):
    total: int
    page: int
    size: int
