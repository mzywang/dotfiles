#!/usr/bin/env bash
#
# Installs/reloads the local.kanata.unlock-watcher LaunchAgent (see
# launchd/local.kanata.unlock-watcher.plist and
# .config/kanata/kanata_unlock_watcher.sh).
#
# Safe to re-run any time. Requires sudo once to install the sudoers drop-in
# (see README) so the agent can kickstart system daemons on screen unlock.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="$DOTFILES_DIR/launchd/local.kanata.unlock-watcher.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/local.kanata.unlock-watcher.plist"
SUDOERS_SRC="$DOTFILES_DIR/launchd/sudoers.kanata"
SUDOERS_DEST="/etc/sudoers.d/kanata"

echo "==> Installing passwordless sudo for kanata daemon kickstart"
if [[ -f "$SUDOERS_DEST" ]]; then
  echo "already installed at $SUDOERS_DEST"
else
  sed "s#__USER__#$(whoami)#g" "$SUDOERS_SRC" | sudo tee "$SUDOERS_DEST" > /dev/null
  sudo chown root:wheel "$SUDOERS_DEST"
  sudo chmod 440 "$SUDOERS_DEST"
  sudo visudo -cf "$SUDOERS_DEST"
fi

if launchctl print "gui/$(id -u)/local.kanata.unlock-watcher" &>/dev/null; then
  echo "==> Stopping existing local.kanata.unlock-watcher agent"
  launchctl bootout "gui/$(id -u)/local.kanata.unlock-watcher" 2>/dev/null || true
fi

echo "==> Installing local.kanata.unlock-watcher"
sed "s#__HOME__#$HOME#g" "$PLIST_SRC" > "$PLIST_DEST"
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo "==> Status:"
launchctl print "gui/$(id -u)/local.kanata.unlock-watcher" 2>/dev/null | head -15 || true
