#!/usr/bin/env bash
#
# Bootstrap a fresh Ubuntu machine (e.g. a new DigitalOcean droplet) with:
#   - a non-root "brewuser" account (Homebrew refuses to run as root)
#   - Homebrew (Linuxbrew)
#   - the packages in packages.yaml (currently: gh, tmux)
#   - the Claude Code CLI
#
# Usage (as root, right after SSH-ing into a fresh box):
#   git clone https://github.com/mzywang/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/ubuntu-setup/bootstrap.sh
#
# Everything below the "brewuser" setup runs as brewuser, not root.
set -euo pipefail

BREW_USER="brewuser"

if [[ "$(id -u)" -eq 0 ]]; then
  if ! id -u "$BREW_USER" >/dev/null 2>&1; then
    echo "==> Creating $BREW_USER"
    adduser --disabled-password --gecos "" "$BREW_USER"
    usermod -aG sudo "$BREW_USER"
    echo "$BREW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$BREW_USER"
    chmod 0440 "/etc/sudoers.d/$BREW_USER"
  fi

  BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOTFILES_ROOT="$(cd "$BOOTSTRAP_DIR/.." && pwd)"
  BREW_USER_HOME="$(getent passwd "$BREW_USER" | cut -d: -f6)"
  BREW_USER_DOTFILES="$BREW_USER_HOME/.dotfiles"

  # Give brewuser its own copy of this checkout so it doesn't need access
  # to wherever root cloned it (e.g. under /root, which brewuser can't read).
  if [[ "$DOTFILES_ROOT" != "$BREW_USER_DOTFILES" ]]; then
    echo "==> Copying dotfiles to $BREW_USER_DOTFILES"
    rm -rf "$BREW_USER_DOTFILES"
    cp -r "$DOTFILES_ROOT" "$BREW_USER_DOTFILES"
    chown -R "$BREW_USER:$BREW_USER" "$BREW_USER_DOTFILES"
  fi

  echo "==> Continuing as $BREW_USER"
  su - "$BREW_USER" -c "$BREW_USER_DOTFILES/ubuntu-setup/bootstrap.sh"
  exit $?
fi

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$BOOTSTRAP_DIR/packages.yaml"

# Extract a simple YAML list of "- item" entries under a top-level key.
# Handles trailing comments and blank lines; no external yq dependency.
yaml_list() {
  local key="$1"
  awk -v key="$key:" '
    $0 == key { inlist=1; next }
    /^[^[:space:]#]/ { inlist=0 }              # any new top-level key ends the list
    inlist && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "")    # drop the "- " bullet
      sub(/[[:space:]]*#.*$/, "")              # drop trailing comment
      gsub(/[[:space:]]+$/, "")                # drop trailing whitespace
      if (length($0)) print
    }
  ' "$PACKAGES_FILE"
}

[[ -f "$PACKAGES_FILE" ]] || { echo "error: $PACKAGES_FILE not found" >&2; exit 1; }

# --- apt prerequisites for Homebrew on Linux -----------------------------------
echo "==> Installing apt prerequisites for Homebrew"
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git

# Run unattended: skip Homebrew's "press RETURN to continue" prompt and its
# post-install environment hints.
export NONINTERACTIVE=1
export HOMEBREW_NO_ENV_HINTS=1

# --- Homebrew -------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
[[ -x "$BREW_BIN" ]] || BREW_BIN="$HOME/.linuxbrew/bin/brew"

# Make brew available in this shell session.
eval "$("$BREW_BIN" shellenv)"

# Persist it for future shells (idempotent).
SHELLENV_LINE="eval \"\$($BREW_BIN shellenv)\""
touch "$HOME/.bashrc"
grep -qF "$SHELLENV_LINE" "$HOME/.bashrc" || {
  echo "==> Adding Homebrew to \$HOME/.bashrc"
  printf '\n# Homebrew\n%s\n' "$SHELLENV_LINE" >> "$HOME/.bashrc"
}

echo "==> Updating Homebrew"
brew update

# --- Formulae ---------------------------------------------------------------
while IFS= read -r formula; do
  echo "==> $formula"
  brew install "$formula"
done < <(yaml_list formulae)

# --- Claude Code CLI ----------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "==> Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo
echo "Done."
echo "Open a new shell (or 'source ~/.bashrc') to pick up Homebrew and the Claude Code CLI."
echo "Then run 'gh auth login' and 'claude' to finish signing in."
