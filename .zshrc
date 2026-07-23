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
alias nuphy-restart="sudo launchctl kickstart -k system/local.kanata.nuphy"
alias nuphy-install="/Users/michael/mzywang/dotfiles/install_nuphy_runner.sh"
alias builtin-watcher-install="/Users/michael/mzywang/dotfiles/install_builtin_watcher.sh"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# Keep the input line one row above the bottom of the terminal instead of flush
# against it. Before each prompt, scroll up by the full height of the prompt
# block and move the cursor back up, shifting the whole block up one row so a
# blank line is left beneath the `❯` input line. Uses real newlines, so terminal
# scrollback is preserved. The count must match the prompt height: 2 prompt
# lines + 1 for POWERLEVEL9K_PROMPT_ADD_NEWLINE. Bump it if you change either.
autoload -Uz add-zsh-hook
# Skip the first firing: it lands during P10k's instant-prompt output-capture
# window, and the raw printf/tput output trips its "console output detected"
# warning on every new tab.
typeset -g _reserve_bottom_line_first=1
_reserve_bottom_line() {
  if (( _reserve_bottom_line_first )); then
    _reserve_bottom_line_first=0
    return
  fi
  local reserve=4
  printf '\n%.0s' {1..$reserve}
  tput cuu $reserve
}
add-zsh-hook precmd _reserve_bottom_line

# Machine-specific secrets and overrides (not tracked in git).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
