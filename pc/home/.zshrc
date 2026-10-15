# Sensei desktop: portable prompt and workbench, no laptop/Ubuntu environment.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export EDITOR=nvim
export TERMINAL="$HOME/.local/bin/sensei-terminal"
export DBX_CONTAINER_MANAGER=docker
export CARGO_BUILD_JOBS=2
export MAKEFLAGS=-j6
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory sharehistory histignoredups autocd
if [[ -r /usr/share/oh-my-zsh/oh-my-zsh.sh ]]; then
    export ZSH=/usr/share/oh-my-zsh
    ZSH_THEME=""
    plugins=(git sudo fzf)
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit && compinit
fi
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
else
    [[ -r "$HOME/.config/zsh/prompt.zsh" ]] && source "$HOME/.config/zsh/prompt.zsh"
fi
[[ -r "$HOME/.config/fzf/sensei-colors" ]] && export FZF_DEFAULT_OPTS="$(<$HOME/.config/fzf/sensei-colors)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[ccache] )) && export CCACHE_MAXSIZE=5G
alias e=nvim
alias cls=clear
alias py=python3
alias pt=btop
alias t='sensei-tmux'
alias get='sudo pacman -S'
alias upgrade='sudo pacman -Syu'
alias init_venv='python3 -m venv'
alias gpu='nvidia-smi'
# ROS/CUDA project environments are entered explicitly; don't pollute every shell.
