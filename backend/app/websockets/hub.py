"""WebSocket broadcast hub — admin paneldeki değişiklikleri mobil istemcilere iletir.
Tenant-scoped: her işletmenin bağlantıları sadece kendi event'lerini alır."""
import asyncio
import json
from typing import Any
from uuid import UUID

from fastapi import WebSocket


class ConnectionHub:
    def __init__(self) -> None:
        # tenant_id -> set of connections
        self._by_tenant: dict[UUID, set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, ws: WebSocket, tenant_id: UUID) -> None:
        await ws.accept()
        async with self._lock:
            self._by_tenant.setdefault(tenant_id, set()).add(ws)

    async def disconnect(self, ws: WebSocket, tenant_id: UUID) -> None:
        async with self._lock:
            conns = self._by_tenant.get(tenant_id)
            if conns is not None:
                conns.discard(ws)
                if not conns:
                    self._by_tenant.pop(tenant_id, None)

    async def broadcast(
        self, event: str, payload: dict[str, Any], tenant_id: UUID
    ) -> None:
        message = json.dumps({"event": event, "data": payload}, default=str)
        async with self._lock:
            targets = list(self._by_tenant.get(tenant_id, ()))
        dead: list[WebSocket] = []
        for ws in targets:
            try:
                await ws.send_text(message)
            except Exception:
                dead.append(ws)
        if dead:
            async with self._lock:
                conns = self._by_tenant.get(tenant_id)
                if conns is not None:
                    for ws in dead:
                        conns.discard(ws)


hub = ConnectionHub()
