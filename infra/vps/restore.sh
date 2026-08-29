#!/usr/bin/env sh
set -eu

APP_DIR=${APP_DIR:-/root/toptan-panel}

if [ -f "$APP_DIR/.env" ]; then
  set -a
  . "$APP_DIR/.env"
  set +a
fi

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <db-dump-path> [uploads-tar-gz-path]"
  exit 2
fi

DB_DUMP=$1
UPLOADS_ARCHIVE=${2:-}

if [ ! -f "$DB_DUMP" ]; then
  echo "db dump not found: $DB_DUMP"
  exit 1
fi

docker compose exec -T postgres dropdb -U "${POSTGRES_USER:-gokce}" --if-exists "${POSTGRES_DB:-gokce_toptan}"
docker compose exec -T postgres createdb -U "${POSTGRES_USER:-gokce}" "${POSTGRES_DB:-gokce_toptan}"
docker compose exec -T postgres pg_restore -U "${POSTGRES_USER:-gokce}" -d "${POSTGRES_DB:-gokce_toptan}" --clean --if-exists < "$DB_DUMP"

if [ -n "$UPLOADS_ARCHIVE" ]; then
  if [ ! -f "$UPLOADS_ARCHIVE" ]; then
    echo "uploads archive not found: $UPLOADS_ARCHIVE"
    exit 1
  fi
  docker run --rm -v tp_uploads:/uploads -v "$(dirname "$UPLOADS_ARCHIVE"):/restore:ro" alpine:3.20 \
    sh -c "rm -rf /uploads/* && tar -xzf /restore/$(basename "$UPLOADS_ARCHIVE") -C /uploads"
fi

echo "restore ok"
