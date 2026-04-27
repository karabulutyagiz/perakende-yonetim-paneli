"""Platform yöneticisi (tenant'sız super user) oluşturma scripti.

Kullanım:
    python -m app.scripts.create_platform_owner
"""
import asyncio
from getpass import getpass

import typer

from app.db.session import AsyncSessionLocal
from app.services import user_service


async def _create(email: str, full_name: str, password: str) -> None:
    async with AsyncSessionLocal() as db:
        existing = await user_service.get_by_email(db, email)
        if existing:
            typer.echo(f"Bu e-posta zaten kayıtlı: {email}")
            raise typer.Exit(code=1)
        user = await user_service.create_platform_owner(db, email, full_name, password)
        typer.echo(f"Platform yöneticisi oluşturuldu: {user.email} ({user.id})")


def main(
    email: str = typer.Option(..., prompt="E-posta"),
    full_name: str = typer.Option("Platform Yöneticisi", prompt="Ad Soyad"),
) -> None:
    password = getpass("Parola: ")
    confirm = getpass("Parola (tekrar): ")
    if password != confirm:
        typer.echo("Parolalar eşleşmiyor")
        raise typer.Exit(code=1)
    if len(password) < 8:
        typer.echo("Parola en az 8 karakter olmalı")
        raise typer.Exit(code=1)
    asyncio.run(_create(email, full_name, password))


if __name__ == "__main__":
    typer.run(main)
