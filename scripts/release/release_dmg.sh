#!/usr/bin/env bash
set -euo pipefail

# Required environment variables:
#   APPLE_TEAM_ID                 e.g. 55X48AGS79
#   APPLE_ID                      Apple ID email used for notarization
#   APPLE_APP_SPECIFIC_PASSWORD   App-specific password (or use notarytool keychain profile)

if [[ -z "${APPLE_TEAM_ID:-}" || -z "${APPLE_ID:-}" || -z "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "Missing required env vars."
  echo "Set APPLE_TEAM_ID, APPLE_ID, and APPLE_APP_SPECIFIC_PASSWORD."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/EDFViewerMac.xcodeproj"
SCHEME="EDFViewerMac"
CONFIG="Release"
APP_NAME="EDFViewer"
DISPLAY_NAME="EDF Viewer"
OUT_DIR="$ROOT_DIR/build/release"
ARCHIVE_PATH="$OUT_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$OUT_DIR/export"
APP_PATH="$EXPORT_DIR/$APP_NAME.app"
DMG_PATH="$OUT_DIR/$APP_NAME.dmg"
EXPORT_PLIST="$OUT_DIR/ExportOptions.plist"

mkdir -p "$OUT_DIR"

cd "$ROOT_DIR"
xcodegen generate

cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>${APPLE_TEAM_ID}</string>
</dict>
</plist>
PLIST

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -archivePath "$ARCHIVE_PATH" \
  APPLE_TEAM_ID="$APPLE_TEAM_ID"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app not found at $APP_PATH"
  exit 1
fi

hdiutil create \
  -volname "$DISPLAY_NAME" \
  -srcfolder "$APP_PATH" \
  -ov -format UDZO \
  "$DMG_PATH"

codesign --force --sign "Developer ID Application" --timestamp "$DMG_PATH"

xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

xcrun stapler staple "$DMG_PATH"
spctl -a -t open --context context:primary-signature -v "$DMG_PATH"

echo "Release DMG ready: $DMG_PATH"
