# ubuntu-setup

Bootstrap script for a fresh Ubuntu machine.

## Run

```sh
apt-get update && apt-get install -y git
git clone https://github.com/mzywang/dotfiles.git ~/.dotfiles
~/.dotfiles/ubuntu-setup/bootstrap.sh
```

Then sign in:

```sh
su - brewuser
gh auth login
claude
```

## Installs

Homebrew, then via `brew`: `gh`, `tmux` ([`packages.yaml`](packages.yaml)).
Also installs the Claude Code CLI. Safe to re-run.

## brewuser

Homebrew won't run as root, so running the script as root creates a
`brewuser` account (you'll set its password) and does the rest of the
install as that user. Already have a non-root sudo user? Run the script
as that user instead and the `brewuser` step is skipped.
