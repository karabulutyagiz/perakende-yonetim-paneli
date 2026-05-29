"""App Store / Play Store inceleme demo hesabını oluşturur veya onarır.

Idempotent: hesap yoksa APPROVED bir işletme + sahibi açar; varsa parolayı
sıfırlar, tenant'ı approved + active yapar ve abonelik kısıtını kaldırır.
Reviewer her zaman bu kimlikle giriş yapıp uygulamayı tam kullanabilsin.

Kullanım (prod container içinde):
    docker exec tp-backend python -m app.scripts.create_demo_account
"""
import asyncio

from app.db.session import AsyncSessionLocal
from app.models.tenant import TenantStatus
from app.models.user import UserRole
from app.services import user_service

DEMO_EMAIL = "playreview@toptanpanel.com"
DEMO_PASSWORD = "pZ4S7MikKv81soRO"
DEMO_BUSINESS = "ParaSende Demo"
DEMO_FULL_NAME = "App Review"


async def _run() -> None:
    async with AsyncSessionLocal() as db:
        existing = await user_service.get_by_email(db, DEMO_EMAIL)
        if existing is None:
            tenant, user = await user_service.signup_tenant(
                db,
                business_name=DEMO_BUSINESS,
                email=DEMO_EMAIL,
                full_name=DEMO_FULL_NAME,
                password=DEMO_PASSWORD,
            )
            print(f"Demo hesabı oluşturuldu: {user.email} (tenant {tenant.id})")
            return

        if existing.role != UserRole.TENANT_OWNER or existing.tenant is None:
            raise SystemExit(
                f"'{DEMO_EMAIL}' tenant_owner değil (rol: {existing.role}). "
                "Demo hesabı tam erişim için tenant_owner olmalı; bu hesabı silip "
                "scripti tekrar çalıştır."
            )

        await user_service.change_password(db, existing, DEMO_PASSWORD)
        tenant = existing.tenant
        tenant.status = TenantStatus.APPROVED
        tenant.is_active = True
        tenant.paid_until = None
        existing.is_active = True
        await db.commit()
        print(f"Demo hesabı onarıldı: {existing.email} (tenant {tenant.id}, approved)")


if __name__ == "__main__":
    asyncio.run(_run())
