#!/usr/bin/env bash
#
# Waits for the NuPhy Air75 V3 to appear (cable, Bluetooth, or 2.4GHz dongle),
# then runs kanata with nuphy.kbd in the background. A watchdog restarts kanata
# when it exits, wedges in the DriverKit virtual-HID wait loop, or after a
# system wake (lock/unlock and sleep/wake can leave kanata stuck without mods).
#
# Runs as a root LaunchDaemon (see launchd/local.kanata.nuphy.plist).
# $HOME isn't reliably set -- locate configs relative to this script's path.
#
set -uo pipefail

KANATA="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NUPHY_CFG="$KANATA_DIR/nuphy.kbd"
LOG="/Library/Logs/local.kanata.nuphy.log"
VHID_DAEMON="system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon"

POLL_INTERVAL=5
STUCK_VHID_LINES=50
GRAB_TIMEOUT=45

nuphy_present() {
  ioreg -c IOHIDDevice -r -l 2>/dev/null | grep -q "Air75 V3"
}

wait_for_nuphy() {
  while ! nuphy_present; do
    sleep 3
  done
  sleep 2
}

get_wake_time() {
  sysctl -n kern.waketime 2>/dev/null || true
}

ensure_vhid_daemon() {
  launchctl kickstart -k "$VHID_DAEMON" 2>/dev/null || true
  sleep 2
}

stop_kanata() {
  pkill -f -- "--cfg $NUPHY_CFG" 2>/dev/null || true
  sleep 1
}

start_kanata() {
  ensure_vhid_daemon
  "$KANATA" --cfg "$NUPHY_CFG" &
  echo $!
}

recently_grabbed() {
  tail -200 "$LOG" 2>/dev/null | grep -q "keyboard grabbed, entering event processing loop"
}

stuck_in_virtual_hid() {
  local tail_lines non_vhid
  tail_lines=$(tail "$STUCK_VHID_LINES" "$LOG" 2>/dev/null) || return 1
  [[ -n "$tail_lines" ]] || return 1
  non_vhid=$(printf '%s\n' "$tail_lines" | grep -cv "virtual_hid_keyboard_ready true" || true)
  [[ "$non_vhid" -eq 0 ]]
}

last_wake="$(get_wake_time)"

while true; do
  wait_for_nuphy
  stop_kanata

  kanata_pid="$(start_kanata)"
  started_at=$SECONDS

  while nuphy_present && kill -0 "$kanata_pid" 2>/dev/null; do
    current_wake="$(get_wake_time)"
    if [[ -n "$last_wake" && -n "$current_wake" && "$current_wake" != "$last_wake" ]]; then
      break
    fi
    last_wake="$current_wake"

    if (( SECONDS - started_at > GRAB_TIMEOUT )) && ! recently_grabbed; then
      break
    fi

    if stuck_in_virtual_hid; then
      break
    fi

    sleep "$POLL_INTERVAL"
  done

  stop_kanata
  sleep 2
done
