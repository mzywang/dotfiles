#!/usr/bin/env bash
#
# Install the software these dotfiles configure, via Homebrew:
#   Neovim, Vim (only if not already present), zsh, and cmux.
#
# Run this BEFORE install.sh on a fresh machine:
#   ~/.dotfiles/bootstrap.sh   # installs the tools
#   ~/.dotfiles/install.sh     # symlinks the configs
#
set -euo pipefail

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

# --- Neovim -------------------------------------------------------------------
echo "==> Neovim"
brew install neovim

# --- Vim (only if needed) -----------------------------------------------------
if command -v vim >/dev/null 2>&1; then
  echo "==> Vim already present ($(command -v vim)) — skipping"
else
  echo "==> Vim"
  brew install vim
fi

# --- zsh ----------------------------------------------------------------------
echo "==> zsh"
brew install zsh

# --- zsh-autosuggestions ------------------------------------------------------
# Sourced directly from Homebrew's share dir in .zshrc.
echo "==> zsh-autosuggestions"
brew install zsh-autosuggestions

# --- cmux (cask) --------------------------------------------------------------
echo "==> cmux"
brew install --cask cmux

echo
echo "Done. Next: run ./install.sh to symlink your dotfiles."
echo
echo "To make Homebrew's zsh your default shell (optional):"
echo "  echo \"\$(brew --prefix)/bin/zsh\" | sudo tee -a /etc/shells"
echo "  chsh -s \"\$(brew --prefix)/bin/zsh\""
