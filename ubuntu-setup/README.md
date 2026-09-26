# ubuntu-setup

Bootstrap script for a fresh Ubuntu machine.

## Run

```sh
apt-get update && apt-get install -y git
mkdir ~/mzywang && cd ~/mzywang
git clone https://github.com/mzywang/dotfiles.git
./dotfiles/ubuntu-setup/bootstrap.sh
```

Then sign in:

```sh
su - brewuser
gh auth login
claude
```

## Installs

Homebrew, then via `brew`: `gh`, `tmux`, `neovim` ([`packages.yaml`](packages.yaml)).
Links `~/.config/nvim` to [`.config/nvim`](.config/nvim), backing up anything
already there. It's the macOS config without the clipboard commands
(`:CopyRelPath`, `:CopyPwd`), since there's no system clipboard over SSH.
Also installs the Claude Code CLI. Safe to re-run. Finishes by running
`verify.sh` (see below).

## Flags

- `--verify` — check that everything above is installed and on `PATH`,
  without installing anything. Same as running `verify.sh` directly.
- `--teardown` — uninstall Homebrew (and everything it installed: `gh`,
  `tmux`, `neovim`) and remove the Claude Code CLI. The `~/.config/nvim`
  link is left in place. Leaves the `brewuser` account and
  its home directory alone.
- `--rebuild` — `--teardown` immediately followed by a fresh install, in one run.

## brewuser

Homebrew won't run as root, so running the script as root creates a
`brewuser` account (you'll set its password) and does the rest of the
install as that user. Already have a non-root sudo user? Run the script
as that user instead and the `brewuser` step is skipped.

After install/rebuild, future interactive root logins drop straight into
`brewuser` (added to root's `~/.bashrc`) — that's where all the tools above
live. Need an actual root shell instead?

```sh
touch /root/.no-autodrop   # permanent, until you rm it
ssh root@host bash --norc  # one-off
```
