"""invoice payment breakdown fields

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-17

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "invoices",
        sa.Column("cash_amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
    )
    op.add_column(
        "invoices",
        sa.Column("card_amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
    )
    op.add_column(
        "invoices",
        sa.Column("debt_amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
    )

    op.execute(
        "UPDATE invoices SET cash_amount = total WHERE payment_method = 'nakit'"
    )
    op.execute(
        "UPDATE invoices SET card_amount = total WHERE payment_method = 'kart'"
    )
    op.execute(
        "UPDATE invoices SET debt_amount = total WHERE payment_method = 'borc'"
    )

    op.alter_column("invoices", "cash_amount", server_default=None)
    op.alter_column("invoices", "card_amount", server_default=None)
    op.alter_column("invoices", "debt_amount", server_default=None)


def downgrade() -> None:
    op.drop_column("invoices", "debt_amount")
    op.drop_column("invoices", "card_amount")
    op.drop_column("invoices", "cash_amount")
