#!/usr/bin/env bash
#
# User-session watcher: restarts kanata LaunchDaemons after the screen unlocks.
# Kanata 1.12 releases its keyboard grab on lock and should re-grab on unlock,
# but the DriverKit output path can wedge; a kickstart is the reliable fix.
#
# Installed as a LaunchAgent (see launchd/local.kanata.unlock-watcher.plist).
# Requires passwordless sudo for launchctl kickstart -- see README.
#
set -uo pipefail

restart_kanata() {
  /usr/bin/sudo /bin/launchctl kickstart -k system/local.kanata.nuphy
  /usr/bin/sudo /bin/launchctl kickstart -k system/local.kanata.builtin-watcher
}

/usr/bin/log stream --style compact \
  --predicate 'subsystem == "com.apple.loginwindow.logging" AND (eventMessage CONTAINS "ScreenUnlocked" OR eventMessage CONTAINS "screenIsUnlocked")' \
  2>/dev/null | while read -r _; do
  restart_kanata
  sleep 5
done
