# ubuntu-setup

Bootstrap script for a fresh Ubuntu machine — e.g. a new DigitalOcean droplet
used for remote/mobile development. Installs Homebrew, the GitHub CLI, tmux,
and the Claude Code CLI.

## Set up a new machine

1. Create the machine and SSH in as root (e.g. a DigitalOcean droplet via
   Termius).
2. Install git — a fresh Ubuntu image doesn't ship with it, and you need it
   to clone this repo in the first place:
   ```sh
   apt-get update && apt-get install -y git
   ```
3. Clone the dotfiles and run the bootstrap script. You'll be prompted to
   set `brewuser`'s password when it's created, and again whenever a `sudo`
   step needs it:
   ```sh
   git clone https://github.com/mzywang/dotfiles.git ~/.dotfiles
   ~/.dotfiles/ubuntu-setup/bootstrap.sh
   ```
4. Open a new shell as `brewuser` (or `source ~/.bashrc` there), then sign in:
   ```sh
   su - brewuser
   gh auth login
   claude
   ```

## What `bootstrap.sh` does

- If run as root: creates a `brewuser` account (prompting you to set its
  password) with normal, password-backed sudo access — **Homebrew refuses to
  install as root** — copies this dotfiles checkout into `brewuser`'s home
  directory, and re-runs itself as `brewuser` — every install step below
  happens under that account, not root. `sudo` steps as `brewuser` will
  prompt for the password you just set.
- Installs the apt packages Homebrew needs on Linux (`build-essential`,
  `procps`, `curl`, `file`, `git`).
- Installs Homebrew (Linuxbrew) if it isn't already present, and adds
  `brew shellenv` to `~/.bashrc` so it's on `PATH` in future shells.
- Installs every formula listed in [`packages.yaml`](packages.yaml) —
  currently `gh` and `tmux`.
- Installs the [Claude Code CLI](https://claude.ai/install.sh) if it isn't
  already present.

Safe to re-run: creating `brewuser` is a no-op if it already exists, and
`brew install` and the Claude Code installer are both idempotent.

Already have your own non-root sudo user and would rather not create
`brewuser`? Just run `ubuntu-setup/bootstrap.sh` directly as that user — the
root/`brewuser` handoff above only kicks in when the script is run as root.

## Managing packages

[`packages.yaml`](packages.yaml) is the single source of truth for Homebrew
dependencies. Add or remove entries there and re-run `bootstrap.sh`; it reads
the file directly (no `yq` required).

## tmux cheatsheet

- `ctrl-b c` — create a new window
- `ctrl-b 0` / `ctrl-b 1` — switch windows
- `ctrl-d` — exit
