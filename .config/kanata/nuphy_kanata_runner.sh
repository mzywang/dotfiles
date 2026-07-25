#!/usr/bin/env bash
#
# Runs kanata with nuphy.kbd for the NuPhy Air75 V3 (cable, Bluetooth, or dongle).
# Restarts when kanata exits or the NuPhy disconnects.
#
# nuphy.kbd sets macos-continue-if-no-devs-found, so kanata can start before the
# keyboard enumerates and will grab it when it appears.
#
# Runs as a root LaunchDaemon (see launchd/local.kanata.nuphy.plist).
#
set -uo pipefail

KANATA="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NUPHY_CFG="$KANATA_DIR/nuphy.kbd"
VHID_DAEMON="system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon"

log() {
  echo "$(date '+%H:%M:%S') [runner] $*"
}

# Use kanata's own device list -- more reliable than ioreg from a LaunchDaemon.
nuphy_present() {
  "$KANATA" --list 2>/dev/null | grep -q "Air75 V3"
}

stop_kanata() {
  pkill -f -- "--cfg $NUPHY_CFG" 2>/dev/null || true
  sleep 1
}

ensure_vhid_daemon() {
  launchctl kickstart -k "$VHID_DAEMON" 2>/dev/null || true
  sleep 2
}

start_disconnect_monitor() {
  (
    while ! nuphy_present; do
      sleep 2
    done
    log "NuPhy connected, watching for disconnect"
    while nuphy_present; do
      sleep 2
    done
    log "NuPhy disconnected, stopping kanata"
    stop_kanata
  ) &
  echo $!
}

while true; do
  stop_kanata
  ensure_vhid_daemon

  log "starting kanata"
  disconnect_mon="$(start_disconnect_monitor)"

  if ! "$KANATA" --cfg "$NUPHY_CFG"; then
    log "kanata exited with status $?"
  fi

  kill "$disconnect_mon" 2>/dev/null || true
  wait "$disconnect_mon" 2>/dev/null || true
  stop_kanata
  log "restarting in 3s"
  sleep 3
done
