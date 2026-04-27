from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status

from app.core.security import decode_token
from app.db.session import AsyncSessionLocal
from app.models.tenant import TenantStatus
from app.models.user import UserRole
from app.services import user_service
from app.websockets.hub import hub

router = APIRouter(tags=["ws"])


@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket, token: str) -> None:
    """Canlı senkronizasyon kanalı.
    İstemci `?token=<access_token>` query param ile bağlanır.
    Yalnızca tenant_owner + approved+active tenant'ın bağlantısı kabul edilir."""
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
    if not user or not user.is_active or int(payload.get("v", -1)) != user.token_version:
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    if (
        user.role != UserRole.TENANT_OWNER
        or user.tenant_id is None
        or user.tenant is None
        or not user.tenant.is_active
        or user.tenant.status != TenantStatus.APPROVED
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
