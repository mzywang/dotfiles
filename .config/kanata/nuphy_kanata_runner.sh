#!/usr/bin/env bash
#
# Waits for the NuPhy Air75 V3 to appear (cable, Bluetooth, or 2.4GHz dongle),
# then runs kanata with nuphy.kbd in the background. A watchdog restarts kanata
# when it exits, wedges in the DriverKit virtual-HID wait loop, after a system
# wake, or when the NuPhy disconnects and reconnects.
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
GRAB_TIMEOUT=60
MIN_RUN_BEFORE_STUCK_CHECK=15

nuphy_present() {
  ioreg -c IOHIDDevice -r -l 2>/dev/null | grep -q "Air75 V3"
}

wait_for_nuphy() {
  while ! nuphy_present; do
    sleep 3
  done
  # Give macOS/kanata a moment to enumerate the device after ioreg sees it.
  sleep 2
}

log_line_count() {
  if [[ -f "$LOG" ]]; then
    wc -l < "$LOG" | tr -d ' '
  else
    echo 0
  fi
}

session_log() {
  local offset="$1"
  tail -n +"$((offset + 1))" "$LOG" 2>/dev/null
}

grabbed_since() {
  local offset="$1"
  session_log "$offset" | grep -q "keyboard grabbed, entering event processing loop"
}

stuck_in_virtual_hid_since() {
  local offset="$1"
  local tail_lines non_vhid
  tail_lines=$(session_log "$offset" | tail "$STUCK_VHID_LINES") || return 1
  [[ -n "$tail_lines" ]] || return 1
  non_vhid=$(printf '%s\n' "$tail_lines" | grep -cv "virtual_hid_keyboard_ready true" || true)
  [[ "$non_vhid" -eq 0 ]]
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
  "$KANATA" --cfg "$NUPHY_CFG" &
  echo $!
}

last_wake="$(get_wake_time)"

while true; do
  wait_for_nuphy
  stop_kanata

  log_offset="$(log_line_count)"
  kanata_pid="$(start_kanata)"
  started_at=$SECONDS
  recovered_vhid=0

  while nuphy_present && kill -0 "$kanata_pid" 2>/dev/null; do
    current_wake="$(get_wake_time)"
    if [[ -n "$last_wake" && -n "$current_wake" && "$current_wake" != "$last_wake" ]]; then
      break
    fi
    last_wake="$current_wake"

    if grabbed_since "$log_offset"; then
      sleep "$POLL_INTERVAL"
      continue
    fi

    if (( SECONDS - started_at > GRAB_TIMEOUT )); then
      if (( recovered_vhid == 0 )); then
        ensure_vhid_daemon
        recovered_vhid=1
        log_offset="$(log_line_count)"
        stop_kanata
        kanata_pid="$(start_kanata)"
        started_at=$SECONDS
        continue
      fi
      break
    fi

    if (( SECONDS - started_at > MIN_RUN_BEFORE_STUCK_CHECK )) \
      && stuck_in_virtual_hid_since "$log_offset"; then
      if (( recovered_vhid == 0 )); then
        ensure_vhid_daemon
        recovered_vhid=1
        log_offset="$(log_line_count)"
        stop_kanata
        kanata_pid="$(start_kanata)"
        started_at=$SECONDS
        continue
      fi
      break
    fi

    sleep "$POLL_INTERVAL"
  done

  stop_kanata
  sleep 2
done
