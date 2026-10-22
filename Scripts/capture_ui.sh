#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
BINARY="${1:-$ROOT/dist/Locus.app/Contents/MacOS/Locus}"
OUTPUT="${2:-$ROOT/designs/locus-native-home/native-qa}"
mkdir -p "$OUTPUT"
for APPEARANCE in light dark; do
  for ENTRY in \
    home:home:ready rule:rule:ready wifi-rule:wifiRule:ready add-rule:addRule:newWiFi \
    settings:settings:ready activity:activity:ready permission:permission:permission \
    delete:delete:ready fallback:fallback:ready \
    new-wifi-home:home:newWiFi new-ethernet-home:home:newEthernet \
    new-ethernet-add:addRule:newEthernet permission-home:home:permission \
    empty-activity:activity:emptyActivity long-name-home:home:longName \
    long-name-rule:rule:longName many-rules-home:home:manyRules \
    missing-device-rule:rule:missingDevice disconnected-home:home:disconnected \
    paused-home:home:paused error-home:home:error; do
    PARTS=("${(@s/:/)ENTRY}")
    LOCUS_PREVIEW=1 LOCUS_PREVIEW_APPEARANCE="$APPEARANCE" \
      LOCUS_PREVIEW_ROUTE="${PARTS[2]}" LOCUS_PREVIEW_SCENARIO="${PARTS[3]}" \
      LOCUS_PREVIEW_CAPTURE="$OUTPUT/$APPEARANCE-${PARTS[1]}.png" "$BINARY"
    [[ -s "$OUTPUT/$APPEARANCE-${PARTS[1]}.png" ]] || {
      print -u2 "Missing capture: $APPEARANCE-${PARTS[1]}"
      exit 1
    }
  done
done
