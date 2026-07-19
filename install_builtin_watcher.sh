#!/usr/bin/env bash
#
# Installs/reloads the local.kanata.builtin-watcher LaunchDaemon (see
# launchd/local.kanata.builtin-watcher.plist and
# .config/kanata/nuphy_builtin_keyboard_watcher.sh), removing the older
# static local.kanata.builtin-cmd-tab daemon if it's still present -- the two
# can't run at once since they fight over the same built-in keyboard device.
#
# Safe to re-run any time (e.g. after editing the watcher plist or script);
# it boots out whatever's currently running and reinstalls from the repo.
#
# Requires sudo.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_DEST="/Library/LaunchDaemons/local.kanata.builtin-watcher.plist"
OLD_PLIST_DEST="/Library/LaunchDaemons/local.kanata.builtin-cmd-tab.plist"

if [[ -f "$OLD_PLIST_DEST" ]]; then
  echo "==> Removing old local.kanata.builtin-cmd-tab daemon"
  sudo launchctl bootout system/local.kanata.builtin-cmd-tab 2>/dev/null || true
  sudo rm -f "$OLD_PLIST_DEST"
fi

if [[ -f "$PLIST_DEST" ]]; then
  echo "==> Stopping existing local.kanata.builtin-watcher daemon"
  sudo launchctl bootout system/local.kanata.builtin-watcher 2>/dev/null || true
fi

echo "==> Installing local.kanata.builtin-watcher"
sed "s#__HOME__#$HOME#g" "$DOTFILES_DIR/launchd/local.kanata.builtin-watcher.plist" | sudo tee "$PLIST_DEST" > /dev/null
sudo chown root:wheel "$PLIST_DEST"
sudo chmod 644 "$PLIST_DEST"
sudo launchctl bootstrap system "$PLIST_DEST"

echo "==> Status:"
sudo launchctl list | grep -E "kanata|pqrs" || true
