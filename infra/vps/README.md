# VPS Deployment

Production tek VPS kurulumunda backend, PostgreSQL, ürün fotoğrafları ve statik web admin bu compose ile çalışır. AWS/S3 gerekmez; `AWS_ACCESS_KEY_ID` ve `AWS_SECRET_ACCESS_KEY` boş bırakıldığında backend ürün fotoğraflarını kalıcı `tp_uploads` Docker volume'una yazar. Port 80/443 mevcut Caddy tarafından yönetildiği için bu compose Caddy portu açmaz; `shared-net` ağı üzerinden mevcut Caddy'ye bağlanır.

## Sunucu dizini

```bash
/root/toptan-panel
├── backend/
├── web-static/
├── docker-compose.yml
├── nginx.conf
├── backup.sh
├── restore.sh
├── .env
└── backend/.env
```

Kalıcı veriler Docker volume'larında tutulur:

```bash
tp_pgdata   # PostgreSQL verisi
tp_uploads  # Ürün fotoğrafları / local upload dosyaları
```

## Canlı domain

`toptanperakende.online` ve `www.toptanperakende.online` A kayıtları VPS IP'sine dönmelidir. DNS değişmeden Let's Encrypt sertifikası alınamaz; geçici test için `toptanperakende.168-222-180-190.nip.io` route'u vardır.

## Deploy

```bash
docker compose up -d --build
docker compose exec backend python -m app.scripts.create_platform_owner
```

`backend/.env` içinde production local upload için kritik değerler:

```env
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET=
PUBLIC_API_BASE=https://toptanperakende.online/api/v1
```

## Backup

```bash
APP_DIR=/root/toptan-panel /root/toptan-panel/backup.sh
```

Cron önerisi:

```cron
0 * * * * cd /root/toptan-panel && APP_DIR=/root/toptan-panel ./backup.sh >> /root/toptan-panel/backups/cron.log 2>&1
0 22 * * * cd /root/toptan-panel && docker compose exec -T backend python -m app.scripts.recompute_debts >> /root/toptan-panel/backups/cron.log 2>&1
```
