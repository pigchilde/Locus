#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SOURCE="${1:-$ROOT/Resources/LocusIconSource.png}"
ICONSET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing approved icon source: $SOURCE" >&2
  exit 1
fi

MASKED_SOURCE="$ROOT/Resources/LocusDockIcon.png"
swift "$ROOT/Scripts/mask_icon.swift" "$SOURCE" "$MASKED_SOURCE" \
  "$ROOT/Resources/LocusMark.png" "$ROOT/Resources/LocusMenuBarTemplate.png"

mkdir -p "$ICONSET"

sips -z 16 16 "$MASKED_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASKED_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASKED_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASKED_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASKED_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASKED_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASKED_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASKED_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASKED_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$MASKED_SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

echo "$ICONSET"
