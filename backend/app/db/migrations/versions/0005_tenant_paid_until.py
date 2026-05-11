"""tenants.paid_until alanı (manuel takip edilen abonelik bitiş tarihi)

Revision ID: 0005
Revises: 0004
Create Date: 2026-04-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("tenants", sa.Column("paid_until", sa.Date(), nullable=True))


def downgrade() -> None:
    op.drop_column("tenants", "paid_until")
