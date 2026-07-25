#!/usr/bin/env bash
#
# Install these dotfiles on a new machine by symlinking every tracked file
# into $HOME at its matching path. Existing files are backed up first.
#
# Usage:
#   git clone git@github.com:mzywang/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/install.sh
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Repo files that should NOT be linked into $HOME.
EXCLUDES=(
  "install.sh" "bootstrap.sh" "kanata_setup.sh" "install_builtin_watcher.sh" "install_nuphy_runner.sh" "install_unlock_watcher.sh" "packages.yaml" "README.md" ".gitignore"
  "launchd/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist"
  "launchd/local.kanata.nuphy.plist"
  "launchd/local.kanata.builtin-watcher.plist"
  "launchd/local.kanata.unlock-watcher.plist"
  "launchd/sudoers.kanata"
)

is_excluded() {
  local f="$1" e
  for e in "${EXCLUDES[@]}"; do
    [[ "$f" == "$e" ]] && return 0
  done
  return 1
}

link_file() {
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dest="$HOME/$rel"

  mkdir -p "$(dirname "$dest")"

  # Already linked correctly — nothing to do.
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok      $rel"
    return
  fi

  # Back up whatever is currently there (real file, dir, or stale symlink).
  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    echo "backup  $rel -> $BACKUP_DIR/$rel"
  fi

  ln -s "$src" "$dest"
  echo "link    $rel"
}

cd "$DOTFILES_DIR"
while IFS= read -r rel; do
  is_excluded "$rel" && continue
  link_file "$rel"
done < <(git ls-files)

# Seed the git-ignored secrets file sourced by .zshrc, if it doesn't exist yet.
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-specific secrets and overrides. NOT tracked in git.
# Sourced from ~/.zshrc. Add your exports here, e.g.:
# export PAGERDUTY_USER_API_KEY="..."
EOF
  echo "created ~/.zshrc.local (add machine-specific secrets here)"
fi

echo
echo "Done."
[[ -d "$BACKUP_DIR" ]] && echo "Originals backed up under: $BACKUP_DIR"
