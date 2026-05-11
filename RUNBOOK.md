# Toptan Panel — Production Runbook

> Bu dosya hem sunucuda (`/home/ubuntu/RUNBOOK.md`) hem repo köyünde duruyor.
> Acil durumda buradan oku.

## 🔑 Erişim

| Şey | Değer |
|---|---|
| Sunucu | `toptanperakende.online` (IP: `18.197.130.173`) (eu-central-1, EC2 t3.medium) |
| SSH | `ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173` |
| Web Admin | `https://toptanperakende.online/` |
| API | `https://toptanperakende.online/api/v1/` |
| Health | `https://toptanperakende.online/health` |
| Platform Owner | `admin@toptanpanel.com` / `<ADMIN_PASSWORD>` |
| S3 backup bucket | `s3://toptanperakende/` (eu-central-1) |
| IAM Role (EC2) | `ToptanPanelEC2BackupRole` |

## 🗄️ Veri kaybı koruması (4 katman)

| Katman | Frekans | Saklama | Konum |
|---|---|---|---|
| L1: EBS | sürekli | EC2 ayakta olduğu sürece | EC2 root volume |
| L2: pg_dump (yerel) | saatte 1 | 14 gün | `/home/ubuntu/backups/` |
| L3: S3 dump | saatte 1 | 30 gün | `s3://toptanperakende/` |
| L4: EBS Snapshot (DLM) | günlük | 7 gün | AWS-managed |

L4 setup'ı için: AWS Console → Lifecycle Manager → EBS Snapshot Policy → instance tag `Backup=daily`.

## 🚨 Acil durumlar

### Sunucu cevap vermiyor
```bash
ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173
docker compose -f ~/toptan-panel/docker-compose.yml ps
docker compose -f ~/toptan-panel/docker-compose.yml logs --tail=100 backend
docker compose -f ~/toptan-panel/docker-compose.yml restart backend
```

### Veriyi geri yükle
```bash
ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173
~/restore.sh list           # mevcut yedekleri listele
~/restore.sh latest         # en son yedeği geri yükle
# veya
~/restore.sh db-20260428-183847.dump
```

### EC2 silindi / başka makinede yeni kurulum
1. AWS Console → yeni EC2 launch (t3.medium, Ubuntu 22.04, security group: SSH/HTTP/HTTPS)
2. IAM Role `ToptanPanelEC2BackupRole`'ü yeni instance'a bağla (S3'e erişsin)
3. Bu repo'yu rsync et: `rsync -az ./ ubuntu@<yeni-ip>:~/toptan-panel/`
4. `~/.env` ve `backend/.env` dosyalarını üret (yeni JWT_SECRET ve POSTGRES_PASSWORD)
5. `docker compose up -d --build`
6. `~/restore.sh latest` ile S3'ten data geri yükle
7. DNS / IP'i mobile/web-admin tarafında güncelle

### Manuel yedekleme tetikle
```bash
ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173 '~/backup.sh'
```

## 🔐 Şifre / secret yönetimi

### Platform owner şifresi değiştir
```bash
ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173 \
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

### JWT_SECRET değiştir
```bash
# Tüm açık session'ları geçersiz kılar (kullanıcılar yeniden login olur)
NEW_SECRET=$(openssl rand -base64 48 | tr -d '=+/' | head -c 64)
ssh ... 'sed -i "s|^JWT_SECRET=.*|JWT_SECRET='$NEW_SECRET'|" ~/toptan-panel/backend/.env'
ssh ... 'docker compose -f ~/toptan-panel/docker-compose.yml restart backend'
```

### Postgres şifresi değiştir
1. Önce yeni şifreyi DB'de set et
2. Sonra `.env` ve `~/.env` dosyalarını güncelle
3. backend container'ı restart et

## 🧪 Smoke test (deploy sonrası)
```bash
curl -s https://toptanperakende.online/health
# {"status":"ok","app":"Toptan Panel","env":"production"}

curl -s -X POST https://toptanperakende.online/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@toptanpanel.com","password":"<ADMIN_PASSWORD>"}' | head -c 200
# {"access_token":"..."}
```

## 📊 Monitoring

```bash
# Backup log
tail -f /home/ubuntu/backups/last-run.log

# Cron loglar
tail -f /home/ubuntu/backups/cron.log

# fail2ban
sudo fail2ban-client status sshd

# Disk
df -h
du -sh /home/ubuntu/backups
docker system df

# Container kaynak kullanımı
docker stats --no-stream

# Postgres bağlantı sayısı
docker exec tp-postgres psql -U gokce -d gokce_toptan -c "SELECT count(*) FROM pg_stat_activity;"
```

## ⚠️ Güvenlik notu

- HTTPS aktif (Caddy + Let's Encrypt, otomatik renew) (domain alınana kadar) — production için ACİL eksik
- iOS ATS plain-HTTP IP exception ile çalışıyor (geçici)
- Domain alınınca: Caddy + Let's Encrypt → 30 dakikalık iş
- Dilediğinde HTTPS açma planı için bana de
