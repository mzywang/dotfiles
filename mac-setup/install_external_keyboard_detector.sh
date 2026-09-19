#!/usr/bin/env bash
#
# Installs/reloads the local.kanata.external-keyboard-detector LaunchAgent
# (see launchd/local.kanata.external-keyboard-detector.plist and
# .config/kanata/external_keyboard_detector.sh).
#
# Required for BLE external keyboards (e.g. Dygma Sonsei): the root built-in
# watcher cannot see them via ioreg/hidutil.
#
# Safe to re-run any time.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="$DOTFILES_DIR/launchd/local.kanata.external-keyboard-detector.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/local.kanata.external-keyboard-detector.plist"
DETECTOR_SCRIPT="$HOME/.config/kanata/external_keyboard_detector.sh"

chmod +x "$DETECTOR_SCRIPT"

if launchctl print "gui/$(id -u)/local.kanata.external-keyboard-detector" &>/dev/null; then
  echo "==> Stopping existing local.kanata.external-keyboard-detector agent"
  launchctl bootout "gui/$(id -u)/local.kanata.external-keyboard-detector" 2>/dev/null || true
fi

echo "==> Installing local.kanata.external-keyboard-detector"
sed "s#__HOME__#$HOME#g" "$PLIST_SRC" > "$PLIST_DEST"
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo "==> Status:"
launchctl print "gui/$(id -u)/local.kanata.external-keyboard-detector" 2>/dev/null | head -15 || true
