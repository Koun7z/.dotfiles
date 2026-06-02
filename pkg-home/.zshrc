conda-init() {
    if [[ ! -x "$(command -v conda)" ]]; then
        source /opt/miniconda3/etc/profile.d/conda.sh
    fi

    if [ -n "$1" ]; then
        conda activate "$1"
    else
        conda activate base
    fi
}

omp-preview() {
    oh-my-posh print preview --force --config "$OMP_CONFIG"
}

DEFAULT_USER="pwoli"

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  true
else
  if [ -x "$(command -v fastfetch)" ]; then
    fastfetch
  fi
fi

#extensions

export ZSH="$HOME/.oh-my-zsh"
HIST_STAMPS="yyyy-mm-dd"
ZSH_THEME="" # Move theme to oh-my-posh
plugins=(
  git
  aliases
  archlinux
  #vi-mode # This one fucks up transient prompt, off for now
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
)
source $ZSH/oh-my-zsh.sh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory


unsetopt BEEP
bindkey -v

export KEYTIMEOUT=1
export MANPATH="/usr/local/man:$MANPATH"
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.spicetify:$PATH

alias omp-conf="nvim ~/.config/oh-my-posh/omp.json"
alias pacman-history="expac --timefmt='%Y-%m-%d %H:%M:%S' '%l\t%n' \$(pacman -Qqe) | sort -r"
alias minicom="minicom -c on "

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# List with eza if available
if [ -x "$(command -v eza)" ]; then
  alias ls='eza --icons --color=auto'
  alias ll='eza --icons --long --header --group --group-directories-first --git'
else
  alias ls='ls --color=auto'
  alias ll='ls -l --color=auto'
fi

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
 export OMP_CONFIG="$HOME/.config/oh-my-posh/omp.json"
else
 export OMP_CONFIG="$HOME/.config/oh-my-posh/omp.json"
fi

eval "$(oh-my-posh init zsh --config "$OMP_CONFIG")"
