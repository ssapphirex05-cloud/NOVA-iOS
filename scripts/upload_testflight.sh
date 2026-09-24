#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

: "${APP_STORE_CONNECT_KEY_ID:?Set APP_STORE_CONNECT_KEY_ID}"
: "${APP_STORE_CONNECT_ISSUER_ID:?Set APP_STORE_CONNECT_ISSUER_ID}"
: "${APP_STORE_CONNECT_API_KEY_PATH:?Set APP_STORE_CONNECT_API_KEY_PATH to AuthKey_*.p8}"

IPA=$(find build/TestFlight -maxdepth 1 -name '*.ipa' -print -quit)
if [[ -z "${IPA:-}" ]]; then
  echo "No IPA found. Run scripts/archive_testflight.sh first." >&2
  exit 1
fi

KEY_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$KEY_DIR"
cp "$APP_STORE_CONNECT_API_KEY_PATH" "$KEY_DIR/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"
chmod 600 "$KEY_DIR/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"

xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA" \
  --apiKey "$APP_STORE_CONNECT_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

echo "Upload accepted by App Store Connect. Wait for Apple processing, then open TestFlight."
