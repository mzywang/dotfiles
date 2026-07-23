#!/usr/bin/env bash
#
# Installs/reloads the local.kanata.nuphy LaunchDaemon (see
# launchd/local.kanata.nuphy.plist and .config/kanata/nuphy_kanata_runner.sh).
#
# Safe to re-run any time (e.g. after editing the runner plist or script);
# it boots out whatever's currently running and reinstalls from the repo.
#
# Requires sudo.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_DEST="/Library/LaunchDaemons/local.kanata.nuphy.plist"

if [[ -f "$PLIST_DEST" ]]; then
  echo "==> Stopping existing local.kanata.nuphy daemon"
  sudo launchctl bootout system/local.kanata.nuphy 2>/dev/null || true
fi

echo "==> Installing local.kanata.nuphy"
sed "s#__HOME__#$HOME#g" "$DOTFILES_DIR/launchd/local.kanata.nuphy.plist" | sudo tee "$PLIST_DEST" > /dev/null
sudo chown root:wheel "$PLIST_DEST"
sudo chmod 644 "$PLIST_DEST"
sudo launchctl bootstrap system "$PLIST_DEST"

echo "==> Status:"
sudo launchctl list | grep -E "kanata|pqrs" || true
