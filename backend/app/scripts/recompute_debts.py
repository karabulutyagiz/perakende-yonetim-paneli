"""Günlük borç durumu güncelleme — cron / EventBridge ile çağrılır.

Kullanım:
    python -m app.scripts.recompute_debts
"""
import asyncio

from app.db.session import AsyncSessionLocal
from app.services import debt_service


async def main() -> None:
    async with AsyncSessionLocal() as db:
        changed = await debt_service.recompute_all_statuses(db)
        print(f"Güncellenen borç kaydı: {changed}")


if __name__ == "__main__":
    asyncio.run(main())
