#!/usr/bin/env bash
# Web admin panelini derler, cache damgası basar ve VPS'e deploy eder.
#
# Neden damga: Flutter web her build'de aynı dosya adlarını üretir
# (index.html → flutter_bootstrap.js → main.dart.js). Tarayıcı bunları bir kez
# cache'lediğinde yeni deploy'u fark etmeyebilir. index.html her zaman no-store
# ile servis edildiği için, içindeki referanslara build'e özel bir ?v=<hash>
# eklemek eski cache'i kesin olarak devre dışı bırakır.
#
# Kullanım:
#   scripts/deploy-web-admin.sh                 # derle + damgala + deploy
#   scripts/deploy-web-admin.sh --skip-build    # mevcut build/web'i kullan
#   scripts/deploy-web-admin.sh --no-deploy     # sadece derle + damgala
set -euo pipefail

HOST="${DEPLOY_HOST:-root@168.222.180.190}"
SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/tuzla_sunucu}"
REMOTE_DIR="${DEPLOY_REMOTE_DIR:-/root/toptan-panel/web-static}"
SITE="${DEPLOY_SITE:-https://toptanperakende.online}"
FLUTTER="${FLUTTER:-flutter}"

SKIP_BUILD=0
NO_DEPLOY=0
for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=1 ;;
    --no-deploy)  NO_DEPLOY=1 ;;
    *) echo "Bilinmeyen argüman: $arg" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/../web-admin"

# 1. Derle — API_BASE define'ı gerekmez, panel same-origin çalışır.
if [ "$SKIP_BUILD" -eq 0 ]; then
  echo "==> flutter build web --release"
  "$FLUTTER" build web --release
else
  echo "==> build atlandı, mevcut build/web kullanılıyor"
fi

WEB=build/web
[ -f "$WEB/main.dart.js" ] || { echo "HATA: $WEB/main.dart.js yok" >&2; exit 1; }

# 2. Damga — uygulama kodu değişmediyse hash de değişmez, gereksiz yeniden
#    indirme olmaz.
STAMP=$(shasum -a 256 "$WEB/main.dart.js" | cut -c1-12)
echo "==> cache damgası: $STAMP"

STAMP="$STAMP" python3 - "$WEB" <<'PYEOF'
import os, re, sys, pathlib

web = pathlib.Path(sys.argv[1])
stamp = os.environ["STAMP"]

def patch(path, fn):
    p = web / path
    src = p.read_text()
    out = fn(src)
    if out == src:
        print(f"    {path:26} → değişiklik yok (zaten damgalı olabilir)")
    else:
        p.write_text(out)
        print(f"    {path:26} → damgalandı")

# index.html: tarayıcı bunu her zaman taze indirir (no-store), dolayısıyla
# buradaki yeni URL eski cache'i kesin olarak atlatır.
patch("index.html", lambda s: s.replace(
    'src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={stamp}"'))

# flutter_bootstrap.js içindeki entrypoint referansı.
patch("flutter_bootstrap.js", lambda s: s.replace(
    '"main.dart.js"', f'"main.dart.js?v={stamp}"'))

# Service worker'ın CORE listesi: SW, istek anahtarını hesaplarken '?v=' ekini
# kırptığı için RESOURCES anahtarları damgasız kalmalı — ama precache'i damgalı
# URL ile yaparsak sayfanın isteği cache'te birebir karşılanır ve main.dart.js
# ikinci kez indirilmez.
def stamp_core(s):
    m = re.search(r"const CORE = \[(.*?)\];", s, re.S)
    if not m:
        raise SystemExit("HATA: flutter_service_worker.js içinde CORE listesi bulunamadı")
    core = m.group(1)
    for name in ("main.dart.js", "flutter_bootstrap.js"):
        core = core.replace(f'"{name}"', f'"{name}?v={stamp}"')
    return s[:m.start(1)] + core + s[m.end(1):]

patch("flutter_service_worker.js", stamp_core)
PYEOF

if [ "$NO_DEPLOY" -eq 1 ]; then
  echo "==> --no-deploy: burada duruldu"
  exit 0
fi

# 3. Deploy — download/ ve legal/ sunucuda yaşar, build'de yoktur;
#    --delete onları silmesin diye hariç tutulur.
RSYNC_OPTS=(-az --delete --exclude='download/' --exclude='legal/')
SSH_CMD="ssh -i $SSH_KEY -o ConnectTimeout=20"

echo "==> silinecek dosya kontrolü (dry-run)"
if rsync "${RSYNC_OPTS[@]}" --dry-run --itemize-changes "$WEB/" "$HOST:$REMOTE_DIR/" -e "$SSH_CMD" | grep -i "^\*deleting"; then
  echo "HATA: yukarıdaki dosyalar silinecekti, deploy durduruldu." >&2
  exit 1
fi
echo "    silinecek dosya yok"

echo "==> rsync"
rsync "${RSYNC_OPTS[@]}" "$WEB/" "$HOST:$REMOTE_DIR/" -e "$SSH_CMD"

# 4. Smoke test
echo "==> smoke test"
curl -fsS --max-time 10 "$SITE/health"; echo
curl -fsS --max-time 30 -o /dev/null -w "    main.dart.js  HTTP %{http_code}  %{size_download} byte\n" "$SITE/main.dart.js"
SERVED=$(curl -fsS --max-time 10 "$SITE/" | grep -o "flutter_bootstrap\.js?v=[0-9a-f]*" | head -1)
echo "    canlıdaki damga: ${SERVED:-BULUNAMADI}"
if [ "$SERVED" = "flutter_bootstrap.js?v=$STAMP" ]; then
  echo "==> deploy tamam"
else
  echo "UYARI: canlıdaki damga beklenenle eşleşmedi (beklenen ?v=$STAMP)" >&2
  exit 1
fi
