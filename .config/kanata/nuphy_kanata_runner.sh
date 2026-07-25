#!/usr/bin/env bash
#
# Runs kanata with nuphy.kbd for the NuPhy Air75 V3 (cable, Bluetooth, or dongle).
# Restarts when kanata exits or the NuPhy disconnects.
#
# Do NOT call `kanata --list` from this script -- it aborts (signal 6) when run as
# a root LaunchDaemon. Use ioreg for device presence instead.
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

nuphy_present() {
  ioreg -c IOHIDDevice -r -l 2>/dev/null | grep -q "Air75 V3"
}

stop_kanata() {
  pkill -f -- "--cfg $NUPHY_CFG" 2>/dev/null || true
  sleep 1
}

while true; do
  while ! nuphy_present; do
    log "waiting for NuPhy"
    sleep 3
  done

  log "NuPhy detected, starting kanata"
  stop_kanata
  sleep 2

  # Stop kanata when the NuPhy disappears so the outer loop can restart cleanly.
  (
    while nuphy_present; do
      sleep 3
    done
    log "NuPhy disconnected, stopping kanata"
    stop_kanata
  ) &
  mon=$!

  "$KANATA" --cfg "$NUPHY_CFG" || log "kanata exited with status $?"

  kill "$mon" 2>/dev/null || true
  wait "$mon" 2>/dev/null || true
  stop_kanata
  sleep 3
done
