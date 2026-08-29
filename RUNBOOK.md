# Zirve Toptan (Toptan Panel) — Production Runbook

> Production tek VPS üzerinde çalışır. Eski AWS EC2 kurulumu (18.197.130.173) **tamamen kapatıldı** —
> `toptanperakende.pem` ve `ubuntu@` ile başlayan eski komutlar geçersizdir.
> Acil durumda buradan oku.

## 🔑 Erişim

| Şey | Değer |
|---|---|
| Sunucu | `168.222.180.190` (paylaşımlı VPS, Ubuntu, TZ: Europe/Istanbul) |
| SSH | `ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190` |
| Uygulama dizini | `/root/toptan-panel` |
| Web Admin | `https://toptanperakende.online/` (kökte doğrudan Flutter admin paneli) |
| API | `https://toptanperakende.online/api/v1/` |
| Health | `https://toptanperakende.online/health` |
| Test domain (DNS beklemeden) | `https://toptanperakende.168-222-180-190.nip.io` |
| Platform Owner | `admin@toptanpanel.com` (ilk şifre sunucuda: `/root/toptan-panel/INITIAL_PLATFORM_OWNER.txt`) |
| DB | container `tp-postgres`, user `gokce`, db `gokce_toptan` |

> ⚠️ Bu sunucu paylaşımlı: transyol, tuzla-icmeler, pakyokayit, football-intel gibi başka
> projeler de aynı makinede çalışır. Sunucu genelini etkileyen işlem yaparken (Caddy restart,
> docker prune, reboot) diğer projeleri de etkilersin.

## 🏗️ Mimari (bu sunucuda)

- Docker Compose projesi `toptan-panel` (`/root/toptan-panel/docker-compose.yml`):
  - `tp-postgres` — postgres:16-alpine, veri `tp_pgdata` volume'unda
  - `tp-backend` — FastAPI; ürün fotoğrafları S3 yerine `tp_uploads` volume'unda (AWS keys boş = local mod)
  - `tp-web` — nginx, `/root/toptan-panel/web-static` içeriğini servis eder (Flutter admin + `legal/` + `download/`)
- Reverse proxy: **paylaşımlı Caddy**, Docker container `transyol-caddy-1`.
  Config host'ta: `/root/transyol/Caddyfile` (container içine `/etc/caddy/Caddyfile` mount).
  `toptanperakende.online` site bloğu `/api/*`, `/api/v1/ws*`, `/health` → `tp-backend:8000`; kalan her şey → `tp-web:80`.
  Ağ: `shared-net` (external Docker network) — compose port açmaz.
- HTTPS: Caddy + Let's Encrypt, otomatik renew. fail2ban aktif.

### Caddy değişikliği uygula
```bash
# /root/transyol/Caddyfile düzenle, sonra:
docker exec transyol-caddy-1 caddy reload --config /etc/caddy/Caddyfile
# (docker restart transyol-caddy-1 de olur ama diğer sitelere kısa kesinti verir)
```

## 🗄️ Yedekler

| Katman | Frekans | Saklama | Konum |
|---|---|---|---|
| pg_dump (`db-*.dump`) | saatte 1 (cron) | 14 gün | `/root/toptan-panel/backups/` |
| uploads (`uploads-*.tar.gz`) | saatte 1 (cron) | 14 gün | `/root/toptan-panel/backups/` |

Cron (root crontab, `# BEGIN TOPTAN PANEL` bloğu):
- `0 * * * *` → `backup.sh` (log: `backups/cron.log`, `backups/last-run.log`)
- `0 22 * * *` → `recompute_debts` (borç renk durumları, TRT 22:00)

> 🔴 **BİLİNEN RİSK — offsite yedek YOK.** Tüm yedekler sunucunun kendi diskinde.
> Disk/sunucu komple giderse veri kurtarılamaz. Eski EC2'deki saatlik S3 katmanı bu
> sunucuya taşınmadı; sunucudaki genel yedek scriptleri (`/root/yedekler/backup.sh`)
> toptan-panel'i KAPSAMIYOR. Öncelikli iş: rclone/S3 ile offsite senkron eklemek.

### Manuel yedek tetikle
```bash
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190 'APP_DIR=/root/toptan-panel /root/toptan-panel/backup.sh'
```

## 🚨 Acil durumlar

### Site/API cevap vermiyor
```bash
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190
cd /root/toptan-panel
docker compose ps
docker compose logs --tail=100 backend
docker compose restart backend
# Caddy tarafı şüpheliyse:
docker logs --tail=50 transyol-caddy-1
```

### Veriyi geri yükle (DİKKAT: onay sormaz, DB'yi düşürüp yeniden kurar)
```bash
cd /root/toptan-panel
ls backups/                              # mevcut yedekler
./restore.sh backups/db-YYYYMMDDTHHMMSSZ.dump                    # sadece DB
./restore.sh backups/db-....dump backups/uploads-....tar.gz      # DB + ürün fotoğrafları
```

### Sunucu komple giderse / yeni makineye kurulum
1. Yeni VPS: Ubuntu + Docker + (varsa) mevcut Caddy düzeni; `docker network create shared-net`
2. Repo'dan `infra/vps/` içeriğini `/root/toptan-panel/` altına kopyala, `backend/` kaynağını rsync et
3. `.env` (POSTGRES_*) ve `backend/.env` (`backend.env.example`'dan; yeni `JWT_SECRET`, `POSTGRES_PASSWORD`) üret
4. Caddyfile'a `infra/vps/Caddyfile.toptan-panel` bloğunu ekle, DNS A kaydını yeni IP'ye çevir
5. `docker compose up -d --build`
6. Yedekten dön: `./restore.sh <db-dump> <uploads-tar>` — **offsite yedek olmadığı sürece bu adım imkânsız olabilir**
7. Cron'ları kur (`# BEGIN TOPTAN PANEL` bloğu, yukarıda)

## 🚀 Deploy

### Backend
```bash
rsync -az --exclude='.env' --exclude='uploads/' --exclude='__pycache__/' --exclude='.pytest_cache/' \
  backend/ root@168.222.180.190:/root/toptan-panel/backend/ -e 'ssh -i ~/.ssh/tuzla_sunucu'
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190 \
  'cd /root/toptan-panel && docker compose up -d --build backend'
```
(Alembic migration'lar container başlarken otomatik çalışır: `alembic upgrade head`.)

### Web admin
```bash
cd web-admin
flutter build web --release        # API_BASE define gerekmez; same-origin çalışır
rsync -az --delete --exclude='download/' --exclude='legal/' \
  build/web/ root@168.222.180.190:/root/toptan-panel/web-static/ -e 'ssh -i ~/.ssh/tuzla_sunucu'
```
(`--exclude download/ legal/` şart: bu klasörler sunucuda yaşar, build'de yoktur; `--delete` onları silmesin.)

## 🔐 Şifre / secret yönetimi

### Platform owner şifresi değiştir
```bash
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190 \
  'docker exec tp-backend python -c "
import asyncio
from app.db.session import AsyncSessionLocal
from app.services import user_service
async def main():
    async with AsyncSessionLocal() as db:
        u = await user_service.get_by_email(db, \"admin@toptanpanel.com\")
        await user_service.change_password(db, u, \"YENİ_ŞİFRE\")
        print(\"changed\")
asyncio.run(main())"'
```

### JWT_SECRET değiştir (tüm oturumları düşürür)
```bash
NEW_SECRET=$(openssl rand -base64 48 | tr -d '=+/' | head -c 64)
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190 \
  "sed -i 's|^JWT_SECRET=.*|JWT_SECRET=$NEW_SECRET|' /root/toptan-panel/backend/.env && \
   cd /root/toptan-panel && docker compose up -d backend"
```

### Postgres şifresi değiştir
1. Önce DB'de: `docker exec tp-postgres psql -U gokce -d gokce_toptan -c "ALTER USER gokce PASSWORD 'yeni';"`
2. `/root/toptan-panel/.env` ve `/root/toptan-panel/backend/.env` içindeki değerleri güncelle
3. `docker compose up -d backend`

## 🧪 Smoke test (deploy sonrası)
```bash
curl -s https://toptanperakende.online/health
# {"status":"ok",...}

curl -s -X POST https://toptanperakende.online/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@toptanpanel.com","password":"<ADMIN_PASSWORD>"}' | head -c 200
# {"access_token":"..."}
```

## 📊 Monitoring
```bash
ssh -i ~/.ssh/tuzla_sunucu root@168.222.180.190
tail -f /root/toptan-panel/backups/last-run.log     # son yedek özeti
tail -f /root/toptan-panel/backups/cron.log         # cron logları
sudo fail2ban-client status sshd
df -h && du -sh /root/toptan-panel/backups && docker system df
docker stats --no-stream
docker exec tp-postgres psql -U gokce -d gokce_toptan -c "SELECT count(*) FROM pg_stat_activity;"
```

## 📝 Notlar
- `INITIAL_PLATFORM_OWNER.TXT` ilk kurulum şifresini içerir; şifre değiştirildiyse dosyayı sil.
- Marketing sitesi (repo kökündeki Next.js, `out/`) şu an bu sunucuya deploy edilmiş DEĞİL;
  domain kökü doğrudan admin panelini açıyor.
- Mobil uygulama release build'leri define verilmezse `https://toptanperakende.online`'a bağlanır
  (`mobile/lib/core/api/api_config.dart`).
