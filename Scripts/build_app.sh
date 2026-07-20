#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
CONFIGURATION="${1:-release}"
APP="$ROOT/dist/Locus.app"

cd "$ROOT"
swift build -c "$CONFIGURATION" --product Locus
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Locus" "$APP/Contents/MacOS/Locus"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/LocusDockIcon.png" "$APP/Contents/Resources/LocusDockIcon.png"
chmod 755 "$APP/Contents/MacOS/Locus"
rm -f "$APP/Contents/Resources/AppIcon.icns"

xcrun actool \
  --compile "$APP/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$ROOT/dist/asset-info.plist" \
  "$ROOT/Resources/Assets.xcassets"

codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"

echo "$APP"
