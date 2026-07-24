#!/usr/bin/env bash
#
# Manages the single kanata instance that owns the built-in keyboard,
# switching between two configs based on whether the NuPhy Air75 V3 is
# connected (in any mode: cable, Bluetooth, or 2.4GHz dongle):
#   - connected:    builtin_block.kbd (blocks every key -- replicates
#                   Karabiner-Elements' old "disable built-in keyboard
#                   while this device is connected" toggle)
#   - disconnected: builtin_cmd_tab.kbd (just blocks Cmd-Tab, as before)
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

current_cfg=""

start() {
  "$KANATA" --cfg "$1" &
  current_cfg="$1"
}

stop_all() {
  pkill -f -- "--cfg $BLOCK_CFG" 2>/dev/null
  pkill -f -- "--cfg $CMD_TAB_CFG" 2>/dev/null
}

while true; do
  if ioreg -c IOHIDDevice -r -l 2>/dev/null | grep "Air75 V3" > /dev/null; then
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
