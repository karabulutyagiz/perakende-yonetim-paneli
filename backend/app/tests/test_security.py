from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


def test_argon2_roundtrip() -> None:
    hashed = hash_password("S3cret!123")
    assert verify_password("S3cret!123", hashed)
    assert not verify_password("wrong", hashed)


def test_jwt_roundtrip() -> None:
    access = create_access_token("user-123", 0, "tenant-abc", "tenant_owner")
    refresh = create_refresh_token("user-123", 0, "tenant-abc", "tenant_owner")

    access_payload = decode_token(access, "access")
    assert access_payload["sub"] == "user-123"
    assert access_payload["type"] == "access"
    assert access_payload["tid"] == "tenant-abc"
    assert access_payload["role"] == "tenant_owner"

    refresh_payload = decode_token(refresh, "refresh")
    assert refresh_payload["type"] == "refresh"


def test_jwt_type_mismatch() -> None:
    token = create_access_token("x", 0, None, "platform_owner")
    try:
        decode_token(token, "refresh")
    except ValueError:
        return
    raise AssertionError("Tip uyuşmazlığı yakalanmadı")
