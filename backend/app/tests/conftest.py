"""Ortak test kurulumu — in-memory SQLite + FastAPI dependency override."""
import os

os.environ.setdefault("JWT_SECRET", "test-secret-please-do-not-use-in-prod")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_SYNC_URL", "sqlite:///:memory:")
os.environ.setdefault("APP_ENV", "development")
# Testlerde rate limit'i devre dışı bırak (login/refresh çok kez çağrılıyor)
os.environ.setdefault("RATE_LIMIT_LOGIN", "10000/minute")
os.environ.setdefault("RATE_LIMIT_REFRESH", "10000/minute")
os.environ.setdefault("RATE_LIMIT_UPLOAD", "10000/minute")

from collections.abc import AsyncGenerator, AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db
from app.main import create_app
from app.models import (  # noqa: F401  — ensure mappers configured
    Category,
    Customer,
    Debt,
    DebtPayment,
    Invoice,
    InvoiceItem,
    Order,
    OrderItem,
    Product,
)
from app.models.tenant import Tenant, TenantStatus
from app.models.user import User
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
async def tenant(db) -> Tenant:
    t = Tenant(
        name="Test Toptancı",
        contact_email="admin@example.com",
        status=TenantStatus.APPROVED,
        is_active=True,
    )
    db.add(t)
    await db.commit()
    await db.refresh(t)
    return t


@pytest_asyncio.fixture()
async def tenant_b(db) -> Tenant:
    """İkinci işletme — cross-tenant izolasyon testleri için."""
    t = Tenant(
        name="Diğer Toptancı",
        contact_email="other@example.com",
        status=TenantStatus.APPROVED,
        is_active=True,
    )
    db.add(t)
    await db.commit()
    await db.refresh(t)
    return t


@pytest_asyncio.fixture()
async def user(db, tenant) -> User:
    return await user_service.create_tenant_owner(
        db, tenant.id, "admin@example.com", "Test Admin", "StrongPass123!"
    )



@pytest_asyncio.fixture()
async def user_b(db, tenant_b) -> User:
    return await user_service.create_tenant_owner(
        db, tenant_b.id, "other@example.com", "Other Admin", "StrongPass123!"
    )


@pytest_asyncio.fixture()
async def app_client(session_factory) -> AsyncGenerator[AsyncClient, None]:
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


async def _login(client: AsyncClient, email: str, password: str) -> str:
    resp = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


@pytest_asyncio.fixture()
async def auth_client(app_client, user) -> AsyncClient:
    token = await _login(app_client, "admin@example.com", "StrongPass123!")
    app_client.headers["Authorization"] = f"Bearer {token}"
    return app_client


@pytest_asyncio.fixture()
async def auth_client_b(session_factory, user_b) -> AsyncGenerator[AsyncClient, None]:
    """İkinci tenant olarak login olmuş ayrı client — cross-tenant testleri için."""
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
        token = await _login(c, "other@example.com", "StrongPass123!")
        c.headers["Authorization"] = f"Bearer {token}"
        yield c


@pytest.fixture()
def make_auth_header():
    def _make(token: str) -> dict[str, str]:
        return {"Authorization": f"Bearer {token}"}

    return _make
