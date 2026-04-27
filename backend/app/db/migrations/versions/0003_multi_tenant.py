"""multi-tenant: tenants + tenant_id on all data tables + user.role

Revision ID: 0003
Revises: 0002
Create Date: 2026-04-23

"""
from typing import Sequence, Union
from uuid import uuid4

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Sabit ID'ler — mevcut verileri bu default tenant'a bağlıyoruz
DEFAULT_TENANT_ID = "00000000-0000-0000-0000-000000000001"
DEFAULT_TENANT_NAME = "Gökçe Toptan Perakende"


def upgrade() -> None:
    # 1. tenants tablosu ---------------------------------------------------
    tenant_status = postgresql.ENUM(
        "pending", "approved", "suspended", name="tenant_status", create_type=False
    )
    tenant_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "tenants",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("contact_email", sa.String(255), nullable=True),
        sa.Column("contact_phone", sa.String(32), nullable=True),
        sa.Column(
            "status",
            tenant_status,
            nullable=False,
            server_default="pending",
        ),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # 2. Default tenant oluştur (mevcut veriler buna atanacak) ------------
    op.execute(
        sa.text(
            "INSERT INTO tenants (id, name, status, is_active) "
            "VALUES (:id, :name, 'approved', true)"
        ).bindparams(id=DEFAULT_TENANT_ID, name=DEFAULT_TENANT_NAME)
    )

    # 3. user_role enum + users'a role + tenant_id -----------------------
    user_role = postgresql.ENUM(
        "platform_owner", "tenant_owner", name="user_role", create_type=False
    )
    user_role.create(op.get_bind(), checkfirst=True)

    op.add_column(
        "users",
        sa.Column(
            "role",
            user_role,
            nullable=False,
            server_default="tenant_owner",
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "tenant_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("tenants.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )
    op.create_index("ix_users_tenant_id", "users", ["tenant_id"])
    # Mevcut kullanıcıları default tenant'a bağla
    op.execute(
        sa.text("UPDATE users SET tenant_id = :tid").bindparams(tid=DEFAULT_TENANT_ID)
    )
    # Email unique constraint: global → (tenant_id, email) composite
    op.drop_index("ix_users_email", table_name="users")
    op.drop_constraint("users_email_key", "users", type_="unique")
    op.create_index("ix_users_email", "users", ["email"])
    op.create_unique_constraint(
        "uq_users_tenant_email", "users", ["tenant_id", "email"]
    )

    # 4. Data tabloları: categories, customers, products, invoices, debts --
    for table in ("categories", "customers", "products", "invoices", "debts"):
        op.add_column(
            table,
            sa.Column(
                "tenant_id",
                postgresql.UUID(as_uuid=True),
                sa.ForeignKey("tenants.id", ondelete="CASCADE"),
                nullable=True,
            ),
        )
        op.execute(
            sa.text(f"UPDATE {table} SET tenant_id = :tid").bindparams(
                tid=DEFAULT_TENANT_ID
            )
        )
        op.alter_column(table, "tenant_id", nullable=False)
        op.create_index(f"ix_{table}_tenant_id", table, ["tenant_id"])

    # categories.name: global unique → (tenant_id, name) composite
    op.drop_constraint("categories_name_key", "categories", type_="unique")
    op.create_unique_constraint(
        "uq_categories_tenant_name", "categories", ["tenant_id", "name"]
    )


def downgrade() -> None:
    # categories unique geri al
    op.drop_constraint("uq_categories_tenant_name", "categories", type_="unique")
    op.create_unique_constraint("categories_name_key", "categories", ["name"])

    # tenant_id kolonlarını düşür
    for table in ("debts", "invoices", "products", "customers", "categories"):
        op.drop_index(f"ix_{table}_tenant_id", table_name=table)
        op.drop_column(table, "tenant_id")

    # users: tenant_email unique + tenant_id + role geri al
    op.drop_constraint("uq_users_tenant_email", "users", type_="unique")
    op.drop_index("ix_users_email", table_name="users")
    op.create_unique_constraint("users_email_key", "users", ["email"])
    op.create_index("ix_users_email", "users", ["email"])
    op.drop_index("ix_users_tenant_id", table_name="users")
    op.drop_column("users", "tenant_id")
    op.drop_column("users", "role")

    # tenants tablosu
    op.drop_table("tenants")

    # Enum'ları düşür
    sa.Enum(name="user_role").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="tenant_status").drop(op.get_bind(), checkfirst=True)
