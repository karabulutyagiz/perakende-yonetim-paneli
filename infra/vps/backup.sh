#!/usr/bin/env sh
set -eu

APP_DIR=${APP_DIR:-/root/toptan-panel}
BACKUP_DIR=${BACKUP_DIR:-$APP_DIR/backups}
RETENTION_DAYS=${RETENTION_DAYS:-14}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)

if [ -f "$APP_DIR/.env" ]; then
  set -a
  . "$APP_DIR/.env"
  set +a
fi

mkdir -p "$BACKUP_DIR"

docker exec tp-postgres pg_dump -U "${POSTGRES_USER:-gokce}" -d "${POSTGRES_DB:-gokce_toptan}" -Fc > "$BACKUP_DIR/db-$STAMP.dump"
docker run --rm -v tp_uploads:/uploads:ro -v "$BACKUP_DIR:/backups" alpine:3.20 \
  sh -c "cd /uploads && tar -czf /backups/uploads-$STAMP.tar.gz ."

find "$BACKUP_DIR" -type f -name 'db-*.dump' -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -type f -name 'uploads-*.tar.gz' -mtime +"$RETENTION_DAYS" -delete

printf 'backup ok: %s\n' "$STAMP" > "$BACKUP_DIR/last-run.log"
