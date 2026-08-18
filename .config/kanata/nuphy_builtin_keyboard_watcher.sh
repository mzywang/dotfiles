#!/usr/bin/env bash
#
# Manages the single kanata instance that owns the built-in keyboard,
# switching between two configs based on whether an external keyboard is
# connected (NuPhy Air75 V3 in any mode, or Dygma Sonsei over BLE).
# BLE detection runs in a user LaunchAgent (external_keyboard_detector.sh)
# because root LaunchDaemons cannot see Bluetooth HID devices.
#   - connected:    builtin_block.kbd (blocks every key -- replicates
#                   Karabiner-Elements' old "disable built-in keyboard
#                   while this device is connected" toggle)
#   - disconnected: builtin_cmd_tab.kbd (Cmd-Tab block, caps->esc, optional Colemak layer)
#
# Only one process can hold the built-in keyboard device at a time, so this
# always stops one before starting the other rather than running both.
#
# Runs as a root LaunchDaemon (see launchd/local.kanata.builtin-watcher.plist),
# so $HOME isn't reliably set -- locate configs relative to this script's own
# path instead.
#
set -uo pipefail

KANATA="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_CFG="$KANATA_DIR/builtin_block.kbd"
CMD_TAB_CFG="$KANATA_DIR/builtin_cmd_tab.kbd"
BUILTIN_TCP_PORT=7071
LAYER_STATE="$KANATA_DIR/builtin_layer"
EXTERNAL_KEYBOARD_STATE="/var/tmp/kanata-external-keyboard"

current_cfg=""

send_tcp() {
  printf '%s\n' "$1" | nc -w 1 127.0.0.1 "$BUILTIN_TCP_PORT" 2>/dev/null
}

request_current_layer() {
  local line
  while IFS= read -r line; do
    if [[ "$line" == *'"CurrentLayerName"'* ]]; then
      printf '%s' "$line"
      return 0
    fi
  done < <(send_tcp '{"RequestCurrentLayerName":{}}')
  return 1
}

restore_builtin_layer() {
  local layer="qwerty"
  if [[ -f "$LAYER_STATE" ]]; then
    layer="$(tr -d '[:space:]' < "$LAYER_STATE")"
  fi
  [[ "$layer" == "colemak" ]] || return 0

  local i response
  for ((i = 1; i <= 40; i++)); do
    if response="$(request_current_layer)"; then
      if [[ "$response" == *'"name":"colemak"'* ]]; then
        return 0
      fi
      if send_tcp '{"ChangeLayer":{"new":"colemak"}}' | grep -q '"status":"Ok"'; then
        return 0
      fi
    fi
    sleep 0.25
  done
}

start() {
  if [[ "$1" == "$CMD_TAB_CFG" ]]; then
    "$KANATA" --cfg "$1" --port "$BUILTIN_TCP_PORT" &
    current_cfg="$1"
    restore_builtin_layer
  else
    "$KANATA" --cfg "$1" &
    current_cfg="$1"
  fi
}

stop_all() {
  pkill -f -- "--cfg $BLOCK_CFG" 2>/dev/null
  pkill -f -- "--cfg $CMD_TAB_CFG" 2>/dev/null
}

external_keyboard_connected() {
  # BLE keyboards are only visible in the logged-in user session; the detector
  # LaunchAgent writes /var/tmp/kanata-external-keyboard for us to read here.
  if [[ -f "$EXTERNAL_KEYBOARD_STATE" ]] && [[ "$(<"$EXTERNAL_KEYBOARD_STATE")" == "1" ]]; then
    return 0
  fi
  # USB keyboards (e.g. NuPhy dongle) may still be visible to root via ioreg.
  grep -qE 'Air75 V3|Sonsei' < <(ioreg -r -c IOHIDDevice 2>/dev/null | grep '"Product"')
}

while true; do
  if external_keyboard_connected; then
    desired_cfg="$BLOCK_CFG"
  else
    desired_cfg="$CMD_TAB_CFG"
  fi

  if [[ "$current_cfg" != "$desired_cfg" ]]; then
    stop_all
    sleep 0.5
    start "$desired_cfg"
  elif [[ -n "$current_cfg" ]] && ! pgrep -f -- "--cfg $current_cfg" > /dev/null; then
    start "$current_cfg"
  fi

  sleep 3
done
