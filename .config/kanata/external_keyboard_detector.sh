#!/usr/bin/env bash
#
# Polls hidutil in the logged-in user session for external keyboards and writes
# a state file the root built-in watcher reads. BLE devices (e.g. Dygma Sonsei)
# are not visible to root LaunchDaemons via ioreg/hidutil, so detection has to
# run here instead.
#
# Installed as a LaunchAgent (see launchd/local.kanata.external-keyboard-detector.plist).
#
set -uo pipefail

STATE_FILE="/var/tmp/kanata-external-keyboard"
PATTERN='Air75 V3|Sonsei'

while true; do
  # Process substitution avoids pipefail treating hidutil's non-zero exit as failure.
  if grep -qE "$PATTERN" < <(hidutil list 2>/dev/null); then
    echo 1 > "$STATE_FILE"
  else
    echo 0 > "$STATE_FILE"
  fi
  chmod 644 "$STATE_FILE"
  sleep 3
done
