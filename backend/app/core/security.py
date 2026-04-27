"""JWT + Argon2id tabanlı güvenlik yardımcıları."""
from datetime import datetime, timedelta, timezone
from typing import Any, Literal
from uuid import uuid4

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from jose import JWTError, jwt

from app.core.config import settings

_ph = PasswordHasher(
    time_cost=settings.argon2_time_cost,
    memory_cost=settings.argon2_memory_cost,
    parallelism=settings.argon2_parallelism,
)


def hash_password(plain: str) -> str:
    return _ph.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        _ph.verify(hashed, plain)
        return True
    except VerifyMismatchError:
        return False


def needs_rehash(hashed: str) -> bool:
    return _ph.check_needs_rehash(hashed)


TokenType = Literal["access", "refresh"]


def _create_token(
    subject: str,
    token_type: TokenType,
    expires: timedelta,
    token_version: int,
    tenant_id: str | None,
    role: str,
) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": subject,
        "iat": int(now.timestamp()),
        "exp": int((now + expires).timestamp()),
        "type": token_type,
        "jti": str(uuid4()),
        "v": token_version,
        "tid": tenant_id,
        "role": role,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_access_token(
    subject: str, token_version: int, tenant_id: str | None, role: str
) -> str:
    return _create_token(
        subject,
        "access",
        timedelta(minutes=settings.jwt_access_token_minutes),
        token_version,
        tenant_id,
        role,
    )


def create_refresh_token(
    subject: str, token_version: int, tenant_id: str | None, role: str
) -> str:
    return _create_token(
        subject,
        "refresh",
        timedelta(days=settings.jwt_refresh_token_days),
        token_version,
        tenant_id,
        role,
    )


def decode_token(token: str, expected_type: TokenType) -> dict[str, Any]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise ValueError("geçersiz token") from exc
    if payload.get("type") != expected_type:
        raise ValueError(f"beklenmeyen token tipi: {payload.get('type')}")
    return payload
