#!/usr/bin/env bash
#
# Install the software these dotfiles configure, via Homebrew.
# The package list lives in packages.yaml (single source of truth).
#
# Run this BEFORE install.sh on a fresh machine:
#   ~/.dotfiles/bootstrap.sh   # installs the tools
#   ~/.dotfiles/install.sh     # symlinks the configs
#
set -euo pipefail

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

# --- Homebrew -----------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this shell session.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Updating Homebrew"
brew update

# --- Taps ---------------------------------------------------------------------
while IFS= read -r tap; do
  echo "==> tap $tap"
  brew tap "$tap"
done < <(yaml_list taps)

# --- Formulae -----------------------------------------------------------------
while IFS= read -r formula; do
  echo "==> $formula"
  brew install "$formula"
done < <(yaml_list formulae)

# --- Formulae installed only if their command is missing ----------------------
while IFS= read -r entry; do
  cmd="${entry%%=*}"
  formula="${entry#*=}"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "==> $formula already present ($(command -v "$cmd")) — skipping"
  else
    echo "==> $formula"
    brew install "$formula"
  fi
done < <(yaml_list formulae_if_missing)

# --- Casks --------------------------------------------------------------------
while IFS= read -r cask; do
  echo "==> $cask (cask)"
  brew install --cask "$cask"
done < <(yaml_list casks)

echo
echo "Done. Next: run ./install.sh to symlink your dotfiles."
echo
echo "To make Homebrew's zsh your default shell (optional):"
echo "  echo \"\$(brew --prefix)/bin/zsh\" | sudo tee -a /etc/shells"
echo "  chsh -s \"\$(brew --prefix)/bin/zsh\""
