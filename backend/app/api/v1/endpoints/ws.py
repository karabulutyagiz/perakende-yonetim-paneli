from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select

from app.core.security import decode_token
from app.db.session import AsyncSessionLocal
from app.models.tenant import Tenant, TenantStatus
from app.models.user import UserRole
from app.services import user_service
from app.websockets.hub import hub

router = APIRouter(tags=["ws"])


@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket, token: str) -> None:
    """Canlı senkronizasyon kanalı.
    İstemci `?token=<access_token>` query param ile bağlanır.
    Yalnızca tenant_owner + approved+active tenant kabul edilir.
    Customer hesapları tenant içindeki tüm canlı event'leri görmemesi için WS'e alınmaz."""
    try:
        payload = decode_token(token, "access")
    except ValueError:
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        user_id = UUID(payload["sub"])
    except (KeyError, ValueError):
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    async with AsyncSessionLocal() as db:
        user = await user_service.get_by_id(db, user_id)
        tenant = None
        if user and user.tenant_id is not None:
            tenant = (
                await db.execute(select(Tenant).where(Tenant.id == user.tenant_id))
            ).scalar_one_or_none()
    if not user or not user.is_active or int(payload.get("v", -1)) != user.token_version:
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    if (
        user.role != UserRole.TENANT_OWNER
        or user.tenant_id is None
        or tenant is None
        or not tenant.is_active
        or tenant.status != TenantStatus.APPROVED
    ):
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    tenant_id = user.tenant_id
    await hub.connect(ws, tenant_id)
    try:
        while True:
            # Ping / heartbeat — istemciden gelen mesajı yut
            await ws.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        await hub.disconnect(ws, tenant_id)
