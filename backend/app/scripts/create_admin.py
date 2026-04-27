"""Yeni bir işletme (tenant) ve sahibi oluşturma scripti.

Kullanım:
    python -m app.scripts.create_admin

Oluşturulan tenant `approved` statüsünde gelir (manuel onay atlanır).
"""
import asyncio
from getpass import getpass

import typer

from app.db.session import AsyncSessionLocal
from app.models.tenant import TenantStatus
from app.services import user_service


async def _create(business_name: str, email: str, full_name: str, password: str) -> None:
    async with AsyncSessionLocal() as db:
        existing = await user_service.get_by_email(db, email)
        if existing:
            typer.echo(f"Bu e-posta zaten kayıtlı: {email}")
            raise typer.Exit(code=1)
        tenant, user = await user_service.signup_tenant(
            db,
            business_name=business_name,
            email=email,
            full_name=full_name,
            password=password,
        )
        # Script ile oluşturulanlar anında onaylı
        tenant.status = TenantStatus.APPROVED
        await db.commit()
        typer.echo(f"İşletme: {tenant.name} ({tenant.id})")
        typer.echo(f"Sahip:  {user.email} ({user.id})")


def main(
    business_name: str = typer.Option(..., prompt="İşletme adı"),
    email: str = typer.Option(..., prompt="E-posta"),
    full_name: str = typer.Option(..., prompt="Ad Soyad"),
) -> None:
    password = getpass("Parola: ")
    confirm = getpass("Parola (tekrar): ")
    if password != confirm:
        typer.echo("Parolalar eşleşmiyor")
        raise typer.Exit(code=1)
    if len(password) < 8:
        typer.echo("Parola en az 8 karakter olmalı")
        raise typer.Exit(code=1)
    asyncio.run(_create(business_name, email, full_name, password))


if __name__ == "__main__":
    typer.run(main)
