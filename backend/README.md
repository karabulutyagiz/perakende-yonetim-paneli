# Backend — Gökçe Toptan Perakende

FastAPI + SQLAlchemy 2.0 + Alembic + PostgreSQL.

## Geliştirme

```bash
pip install -e ".[dev]"
cp ../.env.example .env
# DATABASE_URL ayarla (lokal postgres veya docker-compose)
alembic upgrade head
python -m app.scripts.create_admin
uvicorn app.main:app --reload
```

## Yapı

```
app/
├── api/v1/endpoints/   REST + WS rotaları
├── core/               config, security, rate_limit
├── db/                 base, session, migrations
├── models/             SQLAlchemy modelleri
├── schemas/            Pydantic DTO
├── services/           iş mantığı (auth, product, invoice, debt, report, s3)
├── websockets/         broadcast hub
├── scripts/            admin seed, cron scripts
└── tests/              pytest
```

## Komutlar

```bash
alembic upgrade head                       # migrasyon uygula
alembic revision --autogenerate -m "..."   # yeni migrasyon
python -m app.scripts.create_admin         # ilk kullanıcı
python -m app.scripts.recompute_debts      # günlük borç güncelle
pytest -q                                  # test
ruff check .                               # lint
ruff check . --fix                         # otomatik düzelt
```
