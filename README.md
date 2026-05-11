# Gökçe Toptan Perakende

Toptan satış yapan küçük/orta ölçekli işletmeler için geliştirilmiş stok, müşteri,
fatura, borç ve raporlama yönetim sistemi.

Bu repo bir portfolyo projesi olarak uçtan uca ürün geliştirme yaklaşımını gösterir:
Flutter mobil uygulama, Flutter web admin paneli, FastAPI backend, PostgreSQL veri modeli,
JWT tabanlı auth, WebSocket ile canlı senkronizasyon, testler, Docker lokal geliştirme ortamı
ve AWS üzerinde production altyapısı birlikte tasarlanmıştır.

## Öne Çıkanlar

- **Full-stack ürün:** Mobil uygulama, web admin paneli, REST API, veritabanı ve cloud altyapısı aynı repo içinde.
- **Gerçek iş akışı:** Ürün/kategori/müşteri yönetimi, fatura kesme, stok düşme, borç takibi ve rapor ekranları.
- **Canlı senkronizasyon:** Admin panelindeki değişiklikler WebSocket üzerinden mobil tarafa anlık yansır.
- **Güvenli auth:** Access/refresh token, refresh rotation, `token_version` ile logout/parola değişimi sonrası eski token iptali, Argon2id parola hashleme.
- **Çok kiracılı yapı:** Tenant izolasyonu, platform owner/sudo paneli ve tenant bazlı veri erişimi testlerle doğrulanır.
- **Production odaklı altyapı:** AWS CDK ile ECS Fargate, RDS PostgreSQL, S3, CloudFront, Secrets Manager ve EventBridge cron tanımları.
- **Test ve kalite:** Backend testleri, tenant izolasyon senaryoları, Alembic migrasyonları, Ruff/Mypy ayarları ve GitHub Actions CI.

## Neden Bu Proje?

Bu proje sadece CRUD ekranlarından oluşmaz; gerçek bir işletmenin günlük operasyonlarını
modelleyen, frontend-backend-cloud bütünlüğü olan bir sistemdir. İş başvurularında özellikle
aşağıdaki mühendislik becerilerini göstermek için hazırlanmıştır:

- Ürün ihtiyacını veri modeli, API tasarımı ve kullanıcı arayüzüne dönüştürme
- Mobil ve web istemcilerini aynı backend sözleşmesi üzerinde çalıştırma
- Kimlik doğrulama, yetkilendirme, tenant izolasyonu ve rate limit gibi güvenlik konularını ele alma
- SQLAlchemy 2.0, Alembic ve PostgreSQL ile sürdürülebilir backend mimarisi kurma
- AWS üzerinde container, managed database, object storage, CDN ve scheduled task tasarlama
- Test edilebilir servis katmanları ve kritik iş kuralları için otomasyon yazma

## Demo Notu

Repo public olarak incelenebilir. Production ortamına ait gerçek secret, `.env` veya özel anahtarlar
repoya dahil edilmez; örnek değerler `.env.example` içinde placeholder olarak tutulur.

## Kod İnceleme Rotası

Projeyi hızlı değerlendirmek isteyenler için önerilen okuma sırası:

- `backend/app/api/v1/endpoints/` — REST endpoint'leri ve auth/tenant kontrolleri
- `backend/app/services/` — iş kuralları, borç hesaplama, rapor üretimi ve S3 upload akışı
- `backend/app/models/` — SQLAlchemy veri modeli
- `backend/app/db/migrations/versions/` — Alembic migration geçmişi
- `backend/app/tests/` — auth, fatura, borç ve tenant izolasyon testleri
- `web-admin/lib/features/` — web admin ekranları ve raporlama/sudo paneli
- `mobile/lib/features/` — mobil ürün, fatura ve borç ekranları
- `infra/stacks/` — AWS CDK ile production altyapı tanımları

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
