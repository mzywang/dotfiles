#!/usr/bin/env bash
#
# Toggle Colemak-DH on the built-in keyboard via kanata's TCP server.
# macOS can stay on U.S. QWERTY; kanata remaps keys when the colemak layer
# is active. The chosen layer is persisted so it survives NuPhy connect/disconnect
# cycles that restart the built-in kanata instance.
#
# Requires builtin_cmd_tab.kbd to be running (NuPhy disconnected).
#
set -euo pipefail

KANATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_STATE="$KANATA_DIR/builtin_layer"
PORT=7071
HOST=127.0.0.1

request_current_layer() {
  local line
  while IFS= read -r line; do
    if [[ "$line" == *'"CurrentLayerName"'* ]]; then
      printf '%s' "$line"
      return 0
    fi
  done < <(printf '%s\n' '{"RequestCurrentLayerName":{}}' | nc -w 1 "$HOST" "$PORT" 2>/dev/null)
  return 1
}

send_change_layer() {
  local layer="$1"
  printf '%s\n' "{\"ChangeLayer\":{\"new\":\"$layer\"}}" | nc -w 1 "$HOST" "$PORT" >/dev/null 2>&1
}

wait_for_kanata() {
  local i response
  for ((i = 1; i <= 40; i++)); do
    if response="$(request_current_layer)"; then
      printf '%s' "$response"
      return 0
    fi
    sleep 0.25
  done
  return 1
}

response="$(wait_for_kanata || true)"
if [[ -z "$response" ]]; then
  echo "kanata built-in server not reachable on port $PORT" >&2
  echo "Is the NuPhy disconnected and the builtin watcher running?" >&2
  exit 1
fi

if [[ "$response" == *'"name":"colemak"'* ]]; then
  send_change_layer qwerty
  printf 'qwerty\n' > "$LAYER_STATE"
  echo "Built-in keyboard: QWERTY"
else
  send_change_layer colemak
  printf 'colemak\n' > "$LAYER_STATE"
  echo "Built-in keyboard: Colemak"
fi
