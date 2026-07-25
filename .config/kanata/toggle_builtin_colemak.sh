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

send() {
  printf '%s\n' "$1" | nc -w 1 "$HOST" "$PORT" 2>/dev/null
}

response="$(send '{"RequestCurrentLayerName":{}}' || true)"
if [[ -z "$response" ]]; then
  echo "kanata built-in server not reachable on port $PORT" >&2
  echo "Is the NuPhy disconnected and the builtin watcher running?" >&2
  exit 1
fi

if [[ "$response" == *'"name":"colemak"'* ]]; then
  send '{"ChangeLayer":{"new":"qwerty"}}' >/dev/null
  printf 'qwerty\n' > "$LAYER_STATE"
  echo "Built-in keyboard: QWERTY"
else
  send '{"ChangeLayer":{"new":"colemak"}}' >/dev/null
  printf 'colemak\n' > "$LAYER_STATE"
  echo "Built-in keyboard: Colemak"
fi
