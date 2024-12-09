# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme setup
ZSH_THEME="robbyrussell"

# Plugins configuration
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vi-mode
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# History configuration
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# Key bindings for history search
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Aliases
alias ls="ls --color=auto"

# NVM configuration (ensure directory is portable)
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Powerlevel10k
if [ -d "/opt/homebrew/share/powerlevel10k" ]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Plugins (check dynamically)
if [ -d "/opt/homebrew/share/zsh-autosuggestions" ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [ -d "/opt/homebrew/share/zsh-syntax-highlighting" ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
