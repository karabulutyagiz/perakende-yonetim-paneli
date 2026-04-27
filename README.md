# Gökçe Toptan Perakende

Tek kullanıcılı (firma sahibi) toptan perakende takip uygulaması.
Flutter mobil + Flutter web admin paneli + FastAPI backend + PostgreSQL + AWS.

## Mimari

```
┌─────────────┐      ┌────────────────┐      ┌──────────────┐
│  Mobil App  │◄────►│                │◄────►│  PostgreSQL  │
│  (Flutter)  │  WS  │  FastAPI       │      │  (RDS)       │
└─────────────┘      │  Backend       │      └──────────────┘
                     │  (ECS Fargate) │
┌─────────────┐ REST │                │      ┌──────────────┐
│  Web Admin  │◄────►│                │◄────►│  S3 (images) │
│  (Flutter)  │      └────────────────┘      └──────────────┘
└─────────────┘
```

- **Auth:** JWT (access + refresh rotation), Argon2id hashleme, rate limit
- **DB:** PostgreSQL 16 + Alembic migrasyonları
- **Canlı senkron:** WebSocket — admin panelindeki her değişiklik anında mobile
- **Storage:** S3 presigned URL (frontend doğrudan upload eder)
- **Borç:** 15 gün vade, otomatik renk durumu (yeşil/sarı/kırmızı/gecikti)
- **Rapor:** Dashboard — satış, borç, en çok alan müşteri, kategori dağılımı

## Dizin Yapısı

```
gokce-toptan/
├── backend/          FastAPI + SQLAlchemy + Alembic
├── mobile/           Flutter mobil (Android öncelikli, iOS uyumlu)
├── web-admin/        Flutter Web — yönetim paneli
├── infra/            AWS CDK (Python)
├── docker-compose.yml   Lokal geliştirme
└── .github/workflows/   CI
```

## Hızlı Başlangıç (Lokal)

### 1. Ortamı ayağa kaldır

```bash
cp .env.example .env
docker compose up -d postgres
docker compose up backend
```

Backend: http://localhost:8000 · Docs: http://localhost:8000/docs
Adminer: http://localhost:8080 (server: postgres, user: gokce, pass: gokce)

### 2. İlk admin kullanıcıyı oluştur

```bash
docker compose exec backend python -m app.scripts.create_admin
# E-posta, ad ve parola isteyecek
```

### 3. Web admin panelini çalıştır

```bash
cd web-admin
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000/api/v1
```

### 4. Mobil uygulamayı çalıştır

```bash
cd mobile
flutter pub get
# Android emülatör (10.0.2.2 → host)
flutter run -d emulator-5554
# Fiziksel Android cihazda LAN IP'nizi verin
flutter run --dart-define=API_BASE=http://192.168.1.X:8000/api/v1 \
            --dart-define=WS_BASE=ws://192.168.1.X:8000/api/v1/ws
```

## Backend

```bash
cd backend
pip install -e ".[dev]"
alembic upgrade head
uvicorn app.main:app --reload
pytest
ruff check .
```

Endpoint'ler (`/api/v1` prefix):

- `POST /auth/login` · `POST /auth/refresh` · `GET /auth/me` · `POST /auth/change-password`
- `GET/POST/PUT/DELETE /categories`
- `GET/POST/PUT/DELETE /products` · `POST /products/upload-url`
- `GET/POST/PUT/DELETE /customers`
- `GET/POST /invoices`
- `GET /debts` · `GET /debts/summary` · `POST /debts/payments` · `POST /debts/recompute`
- `GET /reports/summary`
- `WS  /ws?token=<access_token>`

## Borç Renk Kuralı

| Kalan Gün | Durum     | Renk      |
|-----------|-----------|-----------|
| ≥ 8 gün   | Güvenli   | 🟢 Yeşil  |
| 4–7 gün   | Yaklaşıyor| 🟡 Sarı   |
| 0–3 gün   | Acil      | 🔴 Kırmızı|
| < 0 gün   | Gecikti   | ⛔ Koyu kırmızı + "X gün gecikti" |

Günlük cron (`app.scripts.recompute_debts`) bu durumu yeniden hesaplar.
AWS'de EventBridge her gün TRT 01:00'de (UTC 22:00) tetikler.

## AWS Deploy

Ön koşul: AWS CLI + Node.js + Python 3.11 + Flutter yüklü, AWS kimliğiniz hazır.

### 1. Admin paneli statik dosyalarını üret

```bash
cd web-admin
flutter pub get
# İlk deploy'da henüz CloudFront domain'i bilmediğimiz için geçici olarak *
flutter build web --dart-define=API_BASE=https://placeholder/api/v1
```

### 2. İlk `cdk deploy` (wildcard admin origin)

```bash
cd infra
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
npm install -g aws-cdk
cdk bootstrap
cdk deploy --all -c admin_origin=*
```

Çıktıyı not alın: `GokceBackend.BackendUrl`, `GokceFrontend.AdminUrl`, `GokceStorage.BucketName`.

### 3. Admin kullanıcısını yarat

```bash
# ECS task'a exec ile gir
aws ecs execute-command --cluster <cluster> --task <task-arn> \
    --container web --interactive --command "/bin/bash"
# İçeride:
python -m app.scripts.create_admin
```

Ya da lokal'den RDS'e bastion/tunnel üzerinden bağlanarak aynı scripti çalıştırın.

### 4. CORS ve domain'i sıkılaştır

CloudFront domain'i elinizdeyken admin paneli ve CORS'u bu domain'e kilitleyin:

```bash
cd web-admin
flutter build web --dart-define=API_BASE=https://<backend-url>/api/v1
cd ../infra
cdk deploy --all -c admin_origin=https://<cloudfront-domain>
```

### 5. (Opsiyonel) ACM sertifikası + HTTPS

```bash
cdk deploy GokceBackend \
  -c admin_origin=https://<cloudfront-domain> \
  -c backend_certificate_arn=arn:aws:acm:eu-central-1:123:certificate/...
```

Sertifika verildiğinde ALB HTTPS listener + HTTP→HTTPS redirect açılır.

Stack'ler:
- `GokceNetwork` — VPC (2 AZ, NAT gateway)
- `GokceStorage` — S3 bucket (ürün görselleri, CORS + versioning)
- `GokceDatabase` — RDS Postgres 16 (private isolated, 7 gün backup, multi-AZ kapalı — maliyet)
- `GokceBackend` — ECS Fargate + ALB + Secrets Manager (JWT + DB), x-request-id structured logs CloudWatch'ta
- `GokceFrontend` — S3 + CloudFront (admin paneli statik hosting)
- `GokceCron` — EventBridge → ECS task (günlük borç güncelleme, TRT 01:00)

### Smoke test (deploy sonrası)

```bash
API=https://<backend-url>/api/v1
curl -s $API/../health | jq
TOKEN=$(curl -s -X POST $API/auth/login \
  -H 'content-type: application/json' \
  -d '{"email":"admin@x","password":"..."}' | jq -r .access_token)
curl -s $API/auth/me -H "authorization: bearer $TOKEN" | jq
curl -s $API/products -H "authorization: bearer $TOKEN" | jq length
```

## Güvenlik

- Parola: Argon2id (time_cost=3, memory=64MB, parallelism=4)
- JWT: 30 dk access + 14 gün refresh, her refresh'te rotation; `token_version` ile logout/parola değişimi tüm cihazları anında geçersizleştirir
- Rate limit: `/auth/login` 5/dk, `/auth/refresh` 30/dk, `/products/upload-url` 60/dk
- CORS: sadece admin panel domain'i (deploy sırasında `-c admin_origin=...`)
- RDS: private isolated subnet, public erişim yok
- S3: public erişim kapalı, private bucket + presigned URL
- Secrets Manager: JWT + DB kimlikleri runtime'da alan-bazlı enjekte (DB_USER, DB_PASSWORD ayrı)
- Container: non-root user + Docker HEALTHCHECK
- Logging: JSON-structured (request_id + method + path + status + duration_ms) → CloudWatch

## Teknoloji

| Katman   | Teknoloji                                    |
|----------|----------------------------------------------|
| Mobil    | Flutter · Riverpod · Dio · go_router · fl_chart |
| Web Admin| Flutter Web · Riverpod · file_picker         |
| Backend  | Python 3.11 · FastAPI · SQLAlchemy 2.0 · Alembic · Argon2 · python-jose · slowapi |
| DB       | PostgreSQL 16                                |
| Altyapı  | AWS CDK · ECS Fargate · RDS · S3 · CloudFront · EventBridge |
| CI       | GitHub Actions                               |

## Yapılacaklar (opsiyonel / sonraki faz)

- [ ] Mobilde offline cache (hive/isar)
- [ ] PDF makbuz (müşteri için)
- [ ] Stok hareketi log tablosu (hangi fatura ne kadar düşürdü)
- [ ] Route53 kaydıyla admin + api için özel domain otomasyonu
