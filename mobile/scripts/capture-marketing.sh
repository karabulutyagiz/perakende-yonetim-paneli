#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${BUNDLE_ID:-com.parasende.app}"
OUTPUT_DIR="${OUTPUT_DIR:-../public/screenshots/apple/iphone/tr}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 16e}"

mkdir -p "$OUTPUT_DIR"

BOOTED_ID="$(xcrun simctl list devices booted | grep "iPhone" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)"

if [[ -z "$BOOTED_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | grep "$DEVICE_NAME" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')"
  if [[ -z "$DEVICE_ID" ]]; then
    echo "Simulator bulunamadı: $DEVICE_NAME" >&2
    echo "Kullanılabilir cihazlar için: xcrun simctl list devices available" >&2
    exit 1
  fi
  xcrun simctl boot "$DEVICE_ID" || true
  xcrun simctl bootstatus "$DEVICE_ID" -b
else
  DEVICE_ID="$BOOTED_ID"
fi

flutter run \
  -d "$DEVICE_ID" \
  --dart-define=MARKETING_CAPTURE=true \
  --dart-define=API_BASE=http://127.0.0.1:8000/api/v1

APP_CONTAINER="$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data)"
SRC_DIR="$APP_CONTAINER/Documents/marketing/tr"

cp "$SRC_DIR/01-products.png" "$OUTPUT_DIR/01.png"
cp "$SRC_DIR/02-cart.png" "$OUTPUT_DIR/02.png"
cp "$SRC_DIR/03-invoice.png" "$OUTPUT_DIR/03.png"
cp "$SRC_DIR/04-reports.png" "$OUTPUT_DIR/04.png"

mkdir -p "../public/screenshots/android/phone/tr"
cp "$OUTPUT_DIR/01.png" "../public/screenshots/android/phone/tr/01.png"
cp "$OUTPUT_DIR/02.png" "../public/screenshots/android/phone/tr/02.png"
cp "$OUTPUT_DIR/03.png" "../public/screenshots/android/phone/tr/03.png"
cp "$OUTPUT_DIR/04.png" "../public/screenshots/android/phone/tr/04.png"

echo "Marketing screenshots copied to $OUTPUT_DIR"
