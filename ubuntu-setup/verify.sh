#!/usr/bin/env bash
#
# Verify that bootstrap.sh's installs are present and on PATH. Runs
# automatically at the end of bootstrap.sh, and safe to re-run any time
# (as brewuser, or whichever user ran bootstrap.sh) to sanity-check a
# machine — it only reads state, it doesn't install or change anything.
#
# Usage:
#   ~/.../ubuntu-setup/verify.sh
set -uo pipefail   # no -e: run every check and report all failures, not just the first

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$BOOTSTRAP_DIR/packages.yaml"

pass=0
fail=0

ok() {
  echo "ok      $1"
  pass=$((pass + 1))
}

missing() {
  echo "MISSING $1"
  fail=$((fail + 1))
}

# Extract a simple YAML list of "- item" entries under a top-level key.
# Handles trailing comments and blank lines; no external yq dependency.
# Duplicated from bootstrap.sh rather than sourced, so this script stays
# runnable standalone.
yaml_list() {
  local key="$1"
  awk -v key="$key:" '
    $0 == key { inlist=1; next }
    /^[^[:space:]#]/ { inlist=0 }
    inlist && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "")
      sub(/[[:space:]]*#.*$/, "")
      gsub(/[[:space:]]+$/, "")
      if (length($0)) print
    }
  ' "$PACKAGES_FILE"
}

# --- Homebrew --------------------------------------------------------------
BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
[[ -x "$BREW_BIN" ]] || BREW_BIN="$HOME/.linuxbrew/bin/brew"

if [[ -x "$BREW_BIN" ]]; then
  ok "Homebrew installed ($BREW_BIN)"
  # So the checks below see brew/gh/tmux even in a shell that hasn't
  # sourced ~/.bashrc yet (e.g. this script run right after bootstrap.sh).
  eval "$("$BREW_BIN" shellenv)"
else
  missing "Homebrew installed (looked for $BREW_BIN)"
fi

if grep -qF "brew shellenv" "$HOME/.bashrc" 2>/dev/null; then
  ok "Homebrew wired into ~/.bashrc"
else
  missing "Homebrew wired into ~/.bashrc"
fi

BREW_PREFIX="$(dirname "$(dirname "$BREW_BIN")")"

# --- Formulae from packages.yaml --------------------------------------------
if [[ -f "$PACKAGES_FILE" ]]; then
  while IFS= read -r formula; do
    if command -v "$BREW_BIN" >/dev/null 2>&1 && "$BREW_BIN" list --formula "$formula" >/dev/null 2>&1; then
      ok "$formula installed (brew)"
    else
      missing "$formula installed (brew)"
    fi

    resolved="$(command -v "$formula" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
      missing "$formula on PATH"
    elif [[ "$resolved" == "$BREW_PREFIX"/* ]]; then
      ok "$formula on PATH ($resolved)"
    else
      # Found, but not the Homebrew one — e.g. an apt-installed version
      # earlier on PATH. Not a hard failure, just worth flagging.
      echo "WARN    $formula on PATH, but not from Homebrew ($resolved)"
      pass=$((pass + 1))
    fi
  done < <(yaml_list formulae)
else
  missing "$PACKAGES_FILE found"
fi

# --- Claude Code CLI ---------------------------------------------------------
resolved="$(command -v claude 2>/dev/null || true)"
if [[ -n "$resolved" ]]; then
  ok "claude on PATH ($resolved)"
else
  missing "claude on PATH"
fi

echo
echo "$pass ok, $fail missing"
[[ "$fail" -eq 0 ]]
