#!/usr/bin/env bash
#
# Bootstrap a fresh Ubuntu machine (e.g. a new DigitalOcean droplet) with:
#   - a non-root "brewuser" account (Homebrew refuses to run as root)
#   - Homebrew (Linuxbrew)
#   - the packages in packages.yaml (currently: gh, tmux)
#   - the Claude Code CLI
#
# Runs ubuntu-setup/verify.sh at the end to confirm everything above is
# actually installed and on PATH.
#
# Usage (as root, right after SSH-ing into a fresh box):
#   apt-get update && apt-get install -y git   # not preinstalled; needed to clone this repo
#   mkdir ~/mzywang && cd ~/mzywang
#   git clone https://github.com/mzywang/dotfiles.git
#   ./dotfiles/ubuntu-setup/bootstrap.sh
#
# Flags (no flag = install):
#   --verify    Just run verify.sh — same as running it directly.
#   --teardown  Uninstall Homebrew (and everything installed through it —
#               gh, tmux) and remove the Claude Code CLI. Does NOT delete
#               the brewuser account or its home directory; that's left
#               alone on purpose since it may hold work you want to keep.
#   --rebuild   --teardown immediately followed by a fresh install, in one
#               run.
#
# You'll be prompted to set brewuser's password when it's created, and again
# whenever brewuser's own sudo calls below need it (regular, password-backed
# sudo — not passwordless). Everything below the "brewuser" setup runs as
# brewuser, not root.
#
# After install/rebuild, future interactive root logins auto-drop into
# brewuser (added to root's ~/.bashrc). For an actual root shell instead:
#   touch /root/.no-autodrop   (permanent)
#   ssh root@host bash --norc  (one-off)
set -euo pipefail

BREW_USER="brewuser"

ACTION="install"
case "${1:-}" in
  "") ;;
  --verify) ACTION="verify" ;;
  --teardown) ACTION="teardown" ;;
  --rebuild) ACTION="rebuild" ;;
  *) echo "error: unknown flag '$1' (expected --verify, --teardown, or --rebuild)" >&2; exit 1 ;;
esac

if [[ "$(id -u)" -eq 0 ]]; then
  if [[ "$ACTION" == "install" || "$ACTION" == "rebuild" ]]; then
    if ! command -v adduser >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
      echo "==> Installing adduser/sudo/git"
      apt-get update -qq
      apt-get install -y adduser sudo git
    fi

    if ! id -u "$BREW_USER" >/dev/null 2>&1; then
      echo "==> Creating $BREW_USER (you'll be asked to set its password)"
      adduser --gecos "" "$BREW_USER"
      usermod -aG sudo "$BREW_USER"
    fi

    # Make future interactive root logins drop straight into brewuser, since
    # that's where all the tools this script installs actually live.
    ROOT_AUTODROP_MARKER="# Auto-drop into $BREW_USER"
    if ! { [[ -f "$HOME/.bashrc" ]] && grep -qF "$ROOT_AUTODROP_MARKER" "$HOME/.bashrc"; }; then
      echo "==> Making root logins drop into $BREW_USER automatically"
      cat >> "$HOME/.bashrc" <<EOF

$ROOT_AUTODROP_MARKER (bootstrap.sh's tools live there). Skip with:
#   touch /root/.no-autodrop   (permanent)
#   ssh root@host bash --norc  (one-off)
if [[ \$- == *i* ]] && [[ ! -e /root/.no-autodrop ]] && id $BREW_USER &>/dev/null; then
  echo "==> Dropping into $BREW_USER (touch /root/.no-autodrop to disable)"
  exec su --pty - $BREW_USER
fi
EOF
    fi
  elif ! id -u "$BREW_USER" >/dev/null 2>&1; then
    echo "error: $BREW_USER doesn't exist — nothing to $ACTION" >&2
    exit 1
  fi

  BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOTFILES_ROOT="$(cd "$BOOTSTRAP_DIR/.." && pwd)"
  BREW_USER_HOME="$(getent passwd "$BREW_USER" | cut -d: -f6)"

  # Mirror this checkout's path relative to root's own $HOME under brewuser's
  # $HOME too (e.g. ~/mzywang/dotfiles stays mzywang/dotfiles, not just
  # dotfiles) so it lands in the same place you'd expect. Falls back to just
  # the directory name if root cloned it somewhere outside $HOME.
  if [[ "$DOTFILES_ROOT" == "$HOME"/* ]]; then
    REL_DOTFILES="${DOTFILES_ROOT#"$HOME"/}"
  else
    REL_DOTFILES="$(basename "$DOTFILES_ROOT")"
  fi
  BREW_USER_DOTFILES="$BREW_USER_HOME/$REL_DOTFILES"

  # Give brewuser its own copy of this checkout so it doesn't need access
  # to wherever root cloned it (e.g. under /root, which brewuser can't read).
  if [[ "$DOTFILES_ROOT" != "$BREW_USER_DOTFILES" ]]; then
    echo "==> Copying dotfiles to $BREW_USER_DOTFILES"
    rm -rf "$BREW_USER_DOTFILES"
    mkdir -p "$(dirname "$BREW_USER_DOTFILES")"
    cp -r "$DOTFILES_ROOT" "$BREW_USER_DOTFILES"
    chown -R "$BREW_USER:$BREW_USER" "$BREW_USER_DOTFILES"
  fi

  echo "==> Continuing as $BREW_USER"
  # --pty: without it, the handed-off shell has no controlling terminal, so
  # brewuser's own sudo calls below can't prompt for a password and fail
  # with "sudo: a terminal is required to read the password".
  su --pty - "$BREW_USER" -c "$(printf '%q ' "$BREW_USER_DOTFILES/ubuntu-setup/bootstrap.sh" "${1:-}")"
  exit $?
fi

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$BOOTSTRAP_DIR/packages.yaml"

if [[ "$ACTION" == "verify" ]]; then
  exec "$BOOTSTRAP_DIR/verify.sh"
fi

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
[[ -x "$BREW_BIN" ]] || BREW_BIN="$HOME/.linuxbrew/bin/brew"

teardown() {
  export NONINTERACTIVE=1

  if [[ -x "$BREW_BIN" ]]; then
    echo "==> Uninstalling Homebrew (takes gh, tmux, and everything else brew installed with it)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  else
    echo "==> Homebrew not installed, nothing to uninstall"
  fi

  if [[ -f "$HOME/.bashrc" ]]; then
    echo "==> Removing Homebrew from ~/.bashrc"
    sed -i '/^# Homebrew$/,/brew shellenv/d' "$HOME/.bashrc"
  fi

  CLAUDE_BIN="$(command -v claude 2>/dev/null || true)"
  if [[ -n "$CLAUDE_BIN" && "$CLAUDE_BIN" == "$HOME"/* ]]; then
    echo "==> Removing the Claude Code CLI ($CLAUDE_BIN)"
    rm -f "$CLAUDE_BIN"
  elif [[ -n "$CLAUDE_BIN" ]]; then
    echo "==> claude resolves to $CLAUDE_BIN, outside \$HOME — leaving it alone"
  else
    echo "==> Claude Code CLI not found on PATH, nothing to remove"
  fi
}

if [[ "$ACTION" == "teardown" || "$ACTION" == "rebuild" ]]; then
  teardown
  if [[ "$ACTION" == "teardown" ]]; then
    echo
    echo "Done. The $BREW_USER account and its home directory were left in place."
    exit 0
  fi
  echo
  echo "==> Rebuilding: reinstalling everything"
fi

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
echo "==> Verifying installs"
if "$BOOTSTRAP_DIR/verify.sh"; then
  echo
  echo "Done."
  echo "Open a new shell (or 'source ~/.bashrc') to pick up Homebrew and the Claude Code CLI."
  echo "Then run 'gh auth login' and 'claude' to finish signing in."
else
  echo
  echo "Done, but verify.sh found problems above (re-run ubuntu-setup/verify.sh any time to check again)."
  exit 1
fi
