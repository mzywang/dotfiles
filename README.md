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
| `.config/kanata/nuphy.kbd` | kanata config: NuPhy Air75 V3 home row mods (Colemak firmware layout) + Cmd-Tab block |
| `.config/kanata/nuphy_kanata_runner.sh` | waits for the NuPhy to appear, then runs `nuphy.kbd`; used by the `local.kanata.nuphy` LaunchDaemon so boot doesn't race the dongle |
| `.config/kanata/builtin_cmd_tab.kbd` | kanata config: Cmd-Tab block on the built-in keyboard (used when the NuPhy is disconnected) |
| `.config/kanata/builtin_block.kbd` | kanata config: blocks every key on the built-in keyboard (used when the NuPhy is connected) |
| `.config/kanata/nuphy_builtin_keyboard_watcher.sh` | polls for the NuPhy and switches the built-in keyboard's kanata instance between the two configs above |
| `launchd/*.plist` | LaunchDaemon templates for kanata + its VirtualHIDDevice daemon (installed by `kanata_setup.sh`, not symlinked) |
| `packages.yaml` | Homebrew taps / formulae / casks |
| `bootstrap.sh` | Installs software from `packages.yaml` |
| `install.sh` | Symlinks configs into `$HOME` |
| `kanata_setup.sh` | One-time sudo setup: VirtualHIDDevice driver + LaunchDaemons for kanata |
| `install_builtin_watcher.sh` | Installs/reloads just the `local.kanata.builtin-watcher` daemon; re-run any time after editing the watcher plist or script (aliased as `builtin-watcher-install`) |
| `install_nuphy_runner.sh` | Installs/reloads just the `local.kanata.nuphy` daemon; re-run any time after editing the runner plist or script (aliased as `nuphy-install`) |

### Kanata (NuPhy home row mods + Cmd-Tab block + built-in keyboard disable)

Home row mods (`a r s t` → left Cmd/Opt/Ctrl/Shift, `n e i o` → right
Shift/Ctrl/Opt/Cmd, matching the Colemak firmware layout on the NuPhy) run
through [kanata](https://github.com/jtroo/kanata) rather than
Karabiner-Elements — its `tap-hold-tap-keys` action can whitelist specific
"safe interrupt" keys per mod-tap key, which fixes fast same-hand rolls
(e.g. alternating `s`/`t`) misfiring as modifiers, something Karabiner's
elapsed-time-only model can't do. `.config/kanata/nuphy.kbd` is scoped to the
NuPhy by device name (covers cable, Bluetooth, and 2.4GHz dongle modes) and
also blocks Cmd-Tab. Because the dongle can take a while to enumerate after
login, `nuphy_kanata_runner.sh` polls for the NuPhy before starting kanata
instead of launching it directly at boot (which used to fail repeatedly until
the device appeared).

The built-in keyboard is owned by a second, separate kanata instance, but
unlike the NuPhy it can't just run one static config, since we want it to
behave differently depending on whether the NuPhy is around: normally it
should just block Cmd-Tab, but while the NuPhy is connected it should be
fully disabled (replicating Karabiner-Elements' old "disable built-in
keyboard while external keyboard is connected" toggle, so the laptop's own
keys can't double-type alongside the NuPhy). Kanata has no built-in notion of
"device A present → block device B", and macOS device-list config
(`macos-dev-names-include`) isn't live-reloadable anyway, so
`.config/kanata/nuphy_builtin_keyboard_watcher.sh` polls `kanata --list`
every few seconds for the NuPhy and swaps which config owns the built-in
keyboard: `builtin_block.kbd` (blocks every key) while it's connected,
`builtin_cmd_tab.kbd` (just blocks Cmd-Tab) while it's not. Only one process
can hold the device at a time, so the watcher always stops the previous one
before starting the other.

Setup on a new machine, in order:

1. `bootstrap.sh` installs kanata via Homebrew.
2. `install.sh` symlinks the `.kbd` configs and the watcher script into
   `~/.config/kanata/`.
3. Run `./kanata_setup.sh` once (needs sudo) — it installs the
   Karabiner-DriverKit-VirtualHIDDevice driver kanata uses for macOS key
   output, and registers kanata (NuPhy) plus the built-in-keyboard watcher as
   LaunchDaemons so they start at boot and restart if they ever crash.
4. Grant two permissions manually in System Settings → Privacy & Security
   (macOS doesn't allow scripting these): add
   `/opt/homebrew/opt/kanata/bin/kanata` under both **Input Monitoring** and
   **Accessibility**, then restart the daemons:
   ```sh
   sudo launchctl kickstart -k system/local.kanata.nuphy
   sudo launchctl kickstart -k system/local.kanata.builtin-watcher
   ```

Karabiner-Elements is not used at all in this setup and should not be
installed alongside it — it ships a conflicting version of the same
VirtualHIDDevice driver kanata depends on.
