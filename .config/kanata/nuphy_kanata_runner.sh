#!/usr/bin/env bash
#
# Waits for the NuPhy Air75 V3 to appear (cable, Bluetooth, or 2.4GHz dongle),
# then runs kanata with nuphy.kbd. Restarts if kanata exits (e.g. keyboard
# unplugged) after waiting for the device to come back.
#
# Runs as a root LaunchDaemon (see launchd/local.kanata.nuphy.plist).
# $HOME isn't reliably set -- locate configs relative to this script's path.
#
set -uo pipefail

KANATA="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NUPHY_CFG="$KANATA_DIR/nuphy.kbd"

nuphy_present() {
  ioreg -c IOHIDDevice -r -l 2>/dev/null | grep "Air75 V3" > /dev/null
}

wait_for_nuphy() {
  while ! nuphy_present; do
    sleep 3
  done
  # Give macOS/kanata a moment to enumerate the device after ioreg sees it.
  sleep 2
}

while true; do
  wait_for_nuphy
  "$KANATA" --cfg "$NUPHY_CFG"
  sleep 3
done
