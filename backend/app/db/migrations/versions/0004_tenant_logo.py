"""tenants.logo_url alanı

Revision ID: 0004
Revises: 0003
Create Date: 2026-04-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "tenants",
        sa.Column("logo_url", sa.String(1024), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("tenants", "logo_url")
