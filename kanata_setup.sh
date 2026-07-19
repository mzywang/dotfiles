#!/usr/bin/env bash
#
# One-time system-level setup for kanata (NuPhy Air75 V3 home row mods +
# Cmd-Tab blocking on both the NuPhy and the built-in keyboard). Installs the
# Karabiner-DriverKit-VirtualHIDDevice driver kanata depends on for macOS key
# output, and registers kanata + its daemon as LaunchDaemons so they start at
# boot. Requires sudo.
#
# Run this after bootstrap.sh (installs kanata via Homebrew) and install.sh
# (symlinks the .kbd configs into ~/.config/kanata/).
#
# Usage:
#   ~/.dotfiles/kanata_setup.sh
#
set -euo pipefail

DRIVER_VERSION="6.2.0"
DRIVER_PKG_URL="https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${DRIVER_VERSION}/Karabiner-DriverKit-VirtualHIDDevice-${DRIVER_VERSION}.pkg"
MANAGER="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "/Applications/Karabiner-Elements.app" ]]; then
  echo "Karabiner-Elements.app is still installed."
  echo "It ships an incompatible version of the same VirtualHIDDevice driver"
  echo "kanata needs and cannot run alongside it. Uninstall it first (its own"
  echo "uninstaller lives under '/Library/Application Support/org.pqrs/Karabiner-Elements/'),"
  echo "then re-run this script."
  exit 1
fi

echo "==> Installing Karabiner-DriverKit-VirtualHIDDevice v${DRIVER_VERSION}"
if [[ ! -x "$MANAGER" ]]; then
  TMP_PKG="$(mktemp -t karabiner-vhid).pkg"
  curl -L -o "$TMP_PKG" "$DRIVER_PKG_URL"
  sudo installer -pkg "$TMP_PKG" -target /
  rm -f "$TMP_PKG"
else
  echo "already installed, skipping download"
fi

echo "==> Activating the driver (approve the System Extension prompt if one appears)"
sudo "$MANAGER" activate

echo "==> Installing LaunchDaemons"
sudo cp "$DOTFILES_DIR/launchd/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist" /Library/LaunchDaemons/
sed "s#__HOME__#$HOME#g" "$DOTFILES_DIR/launchd/local.kanata.nuphy.plist" | sudo tee /Library/LaunchDaemons/local.kanata.nuphy.plist > /dev/null
sed "s#__HOME__#$HOME#g" "$DOTFILES_DIR/launchd/local.kanata.builtin-cmd-tab.plist" | sudo tee /Library/LaunchDaemons/local.kanata.builtin-cmd-tab.plist > /dev/null

sudo chown root:wheel \
  /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist \
  /Library/LaunchDaemons/local.kanata.nuphy.plist \
  /Library/LaunchDaemons/local.kanata.builtin-cmd-tab.plist
sudo chmod 644 \
  /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist \
  /Library/LaunchDaemons/local.kanata.nuphy.plist \
  /Library/LaunchDaemons/local.kanata.builtin-cmd-tab.plist

sudo launchctl bootstrap system /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
sleep 2
sudo launchctl bootstrap system /Library/LaunchDaemons/local.kanata.nuphy.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/local.kanata.builtin-cmd-tab.plist

cat <<'EOF'

==> Almost done. Two permission grants can't be scripted — macOS requires a
    logged-in user to approve them in System Settings:

    1. Privacy & Security -> Input Monitoring
       Add/enable: /opt/homebrew/opt/kanata/bin/kanata

    2. Privacy & Security -> Accessibility
       Add/enable: /opt/homebrew/opt/kanata/bin/kanata

    After granting both, restart the kanata daemons so they pick it up:
      sudo launchctl kickstart -k system/local.kanata.nuphy
      sudo launchctl kickstart -k system/local.kanata.builtin-cmd-tab

    Check status any time with:
      sudo launchctl list | grep -E "pqrs|kanata"
EOF
