# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Command autosuggestions (installed via Homebrew).
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Powerlevel10k prompt.
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# User configuration
export VALON_ROOT_DIR=~/valon
alias peach="$VALON_ROOT_DIR/front-porch/front_porch/modules/peach/cli/peach $@"
export PATH=$PATH:/Users/michael/.cargo/bin

eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="/Users/michael/google-cloud-sdk/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias k=kubectl
alias pcs="peach commit status"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# Machine-specific secrets and overrides (not tracked in git).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
