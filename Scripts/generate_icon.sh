#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SOURCE="${1:-/private/tmp/locus-app-icon.svg.png}"
ICONSET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing rendered 1024px source: $SOURCE" >&2
  exit 1
fi

MASKED_SOURCE="/private/tmp/locus-app-icon-masked-$$.png"
trap 'rm -f "$MASKED_SOURCE"' EXIT
swift "$ROOT/Scripts/mask_icon.swift" "$SOURCE" "$MASKED_SOURCE"

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
