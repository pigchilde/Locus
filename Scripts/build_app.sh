#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
CONFIGURATION="${1:-release}"
ARCHITECTURE="${2:-native}"
APP="$ROOT/dist/Locus.app"

cd "$ROOT"
BUILD_ARGS=(-c "$CONFIGURATION" --product Locus)
if [[ "$ARCHITECTURE" == "universal" ]]; then
  BUILD_ARGS+=(--arch arm64 --arch x86_64)
elif [[ "$ARCHITECTURE" != "native" ]]; then
  echo "Unsupported architecture mode: $ARCHITECTURE" >&2
  echo "Use 'native' or 'universal'." >&2
  exit 1
fi

swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

rm -rf "$APP"
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

if [[ "$ARCHITECTURE" == "universal" ]]; then
  ARCHS="$(lipo -archs "$APP/Contents/MacOS/Locus")"
  [[ "$ARCHS" == *"arm64"* && "$ARCHS" == *"x86_64"* ]] || {
    echo "Universal build is missing an architecture: $ARCHS" >&2
    exit 1
  }
fi

codesign --force --options runtime --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"

echo "$APP"
