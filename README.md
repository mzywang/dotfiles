# dotfiles

Personal macOS dotfiles: zsh + Powerlevel10k, Neovim, Vim, Ghostty, Zed, git, and cmux.

## Set up a new machine

```sh
git clone git@github.com:mzywang/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh   # install Homebrew + packages (see packages.yaml)
~/.dotfiles/install.sh     # symlink the configs into $HOME
```

Then open a new terminal.

### 1. `bootstrap.sh` — install software

Installs Homebrew (if missing), then every tap, formula, and cask listed in
[`packages.yaml`](packages.yaml) — currently Neovim, Vim, zsh,
zsh-autosuggestions, and cmux. Safe to re-run; `brew install` is idempotent.

### 2. `install.sh` — link configs

Symlinks each tracked dotfile into `$HOME` at its matching path
(`.zshrc`, `.p10k.zsh`, `.vimrc`, `.gitconfig`, `.config/nvim/*`,
`.config/ghostty/config`, `.config/zed/settings.json`, `.config/cmux/cmux.json`).
Anything already at those paths is backed up to `~/.dotfiles-backup/<timestamp>/`
first. Also seeds `~/.zshrc.local` (see Secrets below). Safe to re-run.

## Secrets

Secrets are **not** committed. `.zshrc` sources `~/.zshrc.local`, which is
git-ignored. `install.sh` creates an empty template on a new machine — add your
own exports there, e.g.:

```sh
export PAGERDUTY_USER_API_KEY="..."
```

## Optional: use Homebrew's zsh as your login shell

`bootstrap.sh` installs Homebrew's zsh, but your login shell stays as the
system zsh until you switch it (needs your password):

```sh
echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/zsh"
```

## Managing packages

[`packages.yaml`](packages.yaml) is the single source of truth for Homebrew
dependencies. Add or remove entries there and re-run `bootstrap.sh`; it reads
the file directly (no `yq` required).

## What's included

| Path | Purpose |
| --- | --- |
| `.zshrc` | zsh config (Powerlevel10k, autosuggestions, PATH, aliases) |
| `.p10k.zsh` | Powerlevel10k prompt config |
| `.vimrc` | Vim config |
| `.gitconfig` | git config (identity, delta pager, zdiff3 conflict style) |
| `.config/nvim/` | Neovim config + `lazy-lock.json` plugin lockfile |
| `.config/ghostty/config` | Ghostty terminal config |
| `.config/zed/settings.json` | Zed editor settings |
| `.config/cmux/cmux.json` | cmux config (JSONC) |
| `.config/karabiner/assets/complex_modifications/nuphy_home_row_mods.json` | Karabiner-Elements home row mods, scoped to the NuPhy Air75 V3 keyboard |
| `.config/karabiner/assets/complex_modifications/disable_command_tab.json` | Karabiner-Elements rule disabling Command-Tab |
| `packages.yaml` | Homebrew taps / formulae / casks |
| `bootstrap.sh` | Installs software from `packages.yaml` |
| `install.sh` | Symlinks configs into `$HOME` |

### Karabiner-Elements rules

`install.sh` only symlinks the rule files into
`~/.config/karabiner/assets/complex_modifications/` — two manual steps are
still needed in the Karabiner-Elements app on each machine:

1. **Enable the rule**: Complex Modifications tab → Add rule → enable it.
   Adding the file just makes it available as a predefined rule; it isn't
   active until enabled here.
2. **Grant "Modify events" for the device**: Devices tab → find the device
   (e.g. NuPhy Air75 V3) → make sure event modification is turned on for it.
   Without this, Karabiner sees the device but won't intercept its keys, and
   rules scoped to it via `device_if` silently do nothing.
