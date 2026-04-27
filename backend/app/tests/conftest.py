"""Ortak test kurulumu — in-memory SQLite + FastAPI dependency override."""
import os

os.environ.setdefault("JWT_SECRET", "test-secret-please-do-not-use-in-prod")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_SYNC_URL", "sqlite:///:memory:")
os.environ.setdefault("APP_ENV", "development")

from collections.abc import AsyncGenerator
from typing import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.api.deps import get_current_user
from app.db.base import Base
from app.db.session import get_db
from app.main import create_app
from app.models.user import User  # noqa: F401  — ensure mappers configured
from app.models import (  # noqa: F401
    Category,
    Customer,
    Debt,
    DebtPayment,
    Invoice,
    InvoiceItem,
    Product,
)
from app.services import user_service


@pytest_asyncio.fixture()
async def engine():
    eng = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture()
async def session_factory(engine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=engine, expire_on_commit=False, autoflush=False)


@pytest_asyncio.fixture()
async def db(session_factory) -> AsyncIterator[AsyncSession]:
    async with session_factory() as s:
        yield s


@pytest_asyncio.fixture()
async def user(db) -> User:
    return await user_service.create_admin(
        db, "admin@example.com", "Test Admin", "StrongPass123!"
    )


@pytest_asyncio.fixture()
async def app_client(
    session_factory, user
) -> AsyncGenerator[AsyncClient, None]:
    app = create_app()

    async def _get_db_override() -> AsyncGenerator[AsyncSession, None]:
        async with session_factory() as s:
            try:
                yield s
            except Exception:
                await s.rollback()
                raise

    app.dependency_overrides[get_db] = _get_db_override

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture()
async def auth_client(app_client, user) -> AsyncClient:
    resp = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    assert resp.status_code == 200, resp.text
    token = resp.json()["access_token"]
    app_client.headers["Authorization"] = f"Bearer {token}"
    return app_client


@pytest.fixture()
def make_auth_header():
    def _make(token: str) -> dict[str, str]:
        return {"Authorization": f"Bearer {token}"}

    return _make
