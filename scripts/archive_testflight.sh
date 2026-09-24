#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to your Apple Developer Team ID}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is not installed. Install it with: brew install xcodegen" >&2
  exit 1
fi

XCODE_MAJOR=$(xcodebuild -version | awk '/Xcode/{split($2,a,"."); print a[1]; exit}')
if [[ -z "${XCODE_MAJOR:-}" || "$XCODE_MAJOR" -lt 26 ]]; then
  echo "TestFlight upload requires Xcode 26 or later." >&2
  xcodebuild -version || true
  exit 1
fi

python3 scripts/generate_icons.py

if [[ ! -f NOVA/Resources/GoogleService-Info.plist ]]; then
  echo "Warning: GoogleService-Info.plist is missing. The app can archive, but Firebase push will not work." >&2
fi

xcodegen generate
rm -rf build/NOVA.xcarchive build/TestFlight
mkdir -p build

xcodebuild \
  -project NOVA-iOS.xcodeproj \
  -scheme NOVA \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/NOVA.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  clean archive

xcodebuild \
  -exportArchive \
  -archivePath "$PWD/build/NOVA.xcarchive" \
  -exportPath "$PWD/build/TestFlight" \
  -exportOptionsPlist "$PWD/ExportOptions-TestFlight.plist" \
  -allowProvisioningUpdates

printf '\nReady IPA/export in: %s\n' "$PWD/build/TestFlight"
