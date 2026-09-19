# ubuntu-setup

Bootstrap script for a fresh Ubuntu machine — e.g. a new DigitalOcean droplet
used for remote/mobile development. Installs Homebrew, the GitHub CLI, tmux,
and the Claude Code CLI.

## Set up a new machine

1. Create the machine and SSH in as root (e.g. a DigitalOcean droplet via
   Termius).
2. Create a normal user with sudo access — **Homebrew refuses to install as
   root**:
   ```sh
   adduser <username>
   usermod -aG sudo <username>
   ```
3. Switch to that user and run the bootstrap script:
   ```sh
   su - <username>
   git clone https://github.com/mzywang/dotfiles.git ~/.dotfiles
   ~/.dotfiles/ubuntu-setup/bootstrap.sh
   ```
4. Open a new shell (or `source ~/.bashrc`), then sign in:
   ```sh
   gh auth login
   claude
   ```

## What `bootstrap.sh` does

- Installs the apt packages Homebrew needs on Linux (`build-essential`,
  `procps`, `curl`, `file`, `git`).
- Installs Homebrew (Linuxbrew) if it isn't already present, and adds
  `brew shellenv` to `~/.bashrc` so it's on `PATH` in future shells.
- Installs every formula listed in [`packages.yaml`](packages.yaml) —
  currently `gh` and `tmux`.
- Installs the [Claude Code CLI](https://claude.ai/install.sh) if it isn't
  already present.

Safe to re-run: `brew install` and the Claude Code installer are both
idempotent.

## Managing packages

[`packages.yaml`](packages.yaml) is the single source of truth for Homebrew
dependencies. Add or remove entries there and re-run `bootstrap.sh`; it reads
the file directly (no `yq` required).

## tmux cheatsheet

- `ctrl-b c` — create a new window
- `ctrl-b 0` / `ctrl-b 1` — switch windows
- `ctrl-d` — exit
