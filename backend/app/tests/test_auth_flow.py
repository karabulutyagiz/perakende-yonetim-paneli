"""Login → refresh → logout → token_version invalidation."""
import pytest


@pytest.mark.asyncio
async def test_login_returns_token_pair(app_client, user):
    resp = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["access_token"]
    assert data["refresh_token"]


@pytest.mark.asyncio
async def test_login_wrong_password(app_client, user):
    resp = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "wrong-password"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_refresh_rotation(app_client, user):
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    refresh = login.json()["refresh_token"]
    resp = await app_client.post(
        "/api/v1/auth/refresh", json={"refresh_token": refresh}
    )
    assert resp.status_code == 200
    new = resp.json()
    assert new["access_token"] != login.json()["access_token"]
    assert new["refresh_token"] != refresh


@pytest.mark.asyncio
async def test_me_requires_auth(app_client):
    resp = await app_client.get("/api/v1/auth/me")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_with_token(auth_client):
    resp = await auth_client.get("/api/v1/auth/me")
    assert resp.status_code == 200
    assert resp.json()["email"] == "admin@example.com"


@pytest.mark.asyncio
async def test_logout_invalidates_old_tokens(app_client, user):
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    refresh = login.json()["refresh_token"]

    logout = await app_client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {access}"},
    )
    assert logout.status_code == 204

    # Eski access artık reddedilmeli
    me = await app_client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {access}"}
    )
    assert me.status_code == 401

    # Eski refresh de reddedilmeli
    ref = await app_client.post(
        "/api/v1/auth/refresh", json={"refresh_token": refresh}
    )
    assert ref.status_code == 401


@pytest.mark.asyncio
async def test_delete_account_requires_password_and_confirm(auth_client):
    # Yanlış onay
    bad_confirm = await auth_client.request(
        "DELETE",
        "/api/v1/auth/account",
        json={"password": "StrongPass123!", "confirm": "EVET"},
    )
    assert bad_confirm.status_code == 400

    # Yanlış parola
    bad_pw = await auth_client.request(
        "DELETE",
        "/api/v1/auth/account",
        json={"password": "wrong", "confirm": "SİL"},
    )
    assert bad_pw.status_code == 400


@pytest.mark.asyncio
async def test_delete_account_tenant_owner_wipes_tenant(app_client, user, tenant):
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]
    resp = await app_client.request(
        "DELETE",
        "/api/v1/auth/account",
        headers={"Authorization": f"Bearer {access}"},
        json={"password": "StrongPass123!", "confirm": "SİL"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["scope"] == "tenant"

    # Eski token artık çalışmamalı
    me = await app_client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {access}"}
    )
    assert me.status_code == 401

    # Aynı e-posta ile login imkansız
    relogin = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    assert relogin.status_code == 401


@pytest.mark.asyncio
async def test_change_password_invalidates_old_tokens(app_client, user):
    login = await app_client.post(
        "/api/v1/auth/login",
        json={"email": "admin@example.com", "password": "StrongPass123!"},
    )
    access = login.json()["access_token"]

    resp = await app_client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "current_password": "StrongPass123!",
            "new_password": "EvenStronger456!",
        },
    )
    assert resp.status_code == 204

    me = await app_client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {access}"}
    )
    assert me.status_code == 401
