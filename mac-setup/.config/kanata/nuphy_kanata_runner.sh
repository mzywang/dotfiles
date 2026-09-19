#!/usr/bin/env bash
#
# Runs kanata with nuphy.kbd for the NuPhy Air75 V3 (cable, Bluetooth, or dongle).
#
# nuphy.kbd sets macos-continue-if-no-devs-found, so kanata waits for the NuPhy
# to enumerate and grabs it when it appears. Do not probe for the device here:
# ioreg is unreliable from a root LaunchDaemon, and kanata --list aborts (signal 6).
#
# Runs as a root LaunchDaemon (see launchd/local.kanata.nuphy.plist).
#
set -uo pipefail

KANATA="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NUPHY_CFG="$KANATA_DIR/nuphy.kbd"

log() {
  echo "$(date '+%H:%M:%S') [runner] $*"
}

stop_kanata() {
  pkill -f -- "--cfg $NUPHY_CFG" 2>/dev/null || true
  sleep 1
}

while true; do
  log "starting kanata"
  stop_kanata
  "$KANATA" --cfg "$NUPHY_CFG" || log "kanata exited with status $?"
  log "restarting in 3s"
  sleep 3
done
