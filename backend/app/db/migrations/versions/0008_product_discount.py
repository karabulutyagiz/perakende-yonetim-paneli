"""product discount (percent / amount) + sale-time list price snapshot

Revision ID: 0008
Revises: 0007
Create Date: 2026-09-19

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0008"
down_revision: Union[str, None] = "0007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _is_postgres() -> bool:
    return op.get_bind().dialect.name == "postgresql"


def upgrade() -> None:
    if _is_postgres():
        discount_type = postgresql.ENUM(
            "percent", "amount", name="discount_type", create_type=False
        )
        discount_type.create(op.get_bind(), checkfirst=True)
        discount_col = postgresql.ENUM(
            "percent", "amount", name="discount_type", create_type=False
        )
    else:
        discount_col = sa.Enum("percent", "amount", name="discount_type")

    # Ürün kartındaki indirim tanımı. discount_type NULL = indirim yok.
    op.add_column("products", sa.Column("discount_type", discount_col, nullable=True))
    op.add_column(
        "products",
        sa.Column("discount_value", sa.Numeric(12, 2), nullable=False, server_default="0"),
    )

    # Satış anındaki indirimsiz liste fiyatı — dekontta "önce/sonra" göstermek için.
    # NULL = o satırda indirim uygulanmamış.
    op.add_column(
        "invoice_items", sa.Column("list_unit_price", sa.Numeric(12, 2), nullable=True)
    )
    op.add_column(
        "order_items", sa.Column("list_unit_price", sa.Numeric(12, 2), nullable=True)
    )


def downgrade() -> None:
    op.drop_column("order_items", "list_unit_price")
    op.drop_column("invoice_items", "list_unit_price")
    op.drop_column("products", "discount_value")
    op.drop_column("products", "discount_type")
    if _is_postgres():
        sa.Enum(name="discount_type").drop(op.get_bind(), checkfirst=True)
