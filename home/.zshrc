# ~/.zshrc -- interactive shell. Non-interactive shells (agents, scripts) never
# read this file; keep anything they need in the PATH block below, and keep
# everything else behind the interactive guard at the end of the file.

# --- PATH: one array, deduplicated -------------------------------------------
typeset -U path PATH
path=(
  $HOME/.local/bin
  $HOME/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  /usr/local/go/bin
  $HOME/.spicetify
  /opt/cuda/bin
  $path
)
export PATH

# --- Environment --------------------------------------------------------------
LS_COLORS='rs=0:di=1;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=0;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*.rasi=1;33';
export LS_COLORS
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch $(uname -m)"
export DBX_CONTAINER_MANAGER=docker
export RUSTC_WRAPPER=sccache
export CUDA_INSTALL_PATH=/opt/cuda
export CUDA_HOME=$CUDA_INSTALL_PATH
export CUDA_LIB_PATH=$CUDA_INSTALL_PATH/lib64
export CUDA_BIN_PATH=$CUDA_INSTALL_PATH/bin
export LD_LIBRARY_PATH=/opt/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
[[ -n $SSH_CONNECTION ]] && export EDITOR=vim || export EDITOR=nvim
export KEYTIMEOUT=1
export FZF_BASE=/usr/share/doc/fzf/examples
export FZF_DEFAULT_COMMAND='fd --type file --hidden --no-ignore --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 80% --layout=reverse --prompt="❱ "'
[[ -r ~/.config/fzf/sensei-colors ]] && export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(<~/.config/fzf/sensei-colors)"

# ROS 2 Humble on hosts that have it; matches the container DDS config.
if [[ -f /opt/ros/humble/setup.zsh ]]; then
  source /opt/ros/humble/setup.zsh
  [[ -f ~/ros2_ws/install/setup.zsh ]] && source ~/ros2_ws/install/setup.zsh
  export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ROS_DOMAIN_ID=42 ROS_LOCALHOST_ONLY=0
fi

# --- Interactive only below ---------------------------------------------------
[[ -o interactive ]] || return 0

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS EXTENDED_HISTORY
setopt INTERACTIVE_COMMENTS NO_BEEP

# Completion: compinit reads the dump without the security scan, and rebuilds
# the dump at most once a day.
autoload -Uz compinit
_zdump=${ZDOTDIR:-$HOME}/.zcompdump
if [[ -n $_zdump(#qN.mh+24) ]]; then compinit -i -d "$_zdump"; else compinit -C -d "$_zdump"; fi
unset _zdump
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Plugins. Order matters: fzf-tab wraps completion after compinit; the
# autosuggestions and syntax highlighting wrap the line editor, so they come last.
_sensei_plugin() { [[ -r $1 ]] && source "$1"; }
_sensei_plugin ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh
_sensei_plugin /usr/share/fzf/completion.zsh
_sensei_plugin /usr/share/fzf/key-bindings.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_sensei_plugin /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
_sensei_plugin /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset -f _sensei_plugin

bindkey '^[r' fzf-history-widget
# Local history search; keep arrows for shell/editor/agent navigation.
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi
eval "$(zoxide init zsh)"

# nvm loads on first use, not at shell start (it was most of the startup cost).
export NVM_DIR="$HOME/.nvm"
_nvm_load() {
  unfunction nvm node npm npx 2>/dev/null
  [[ -s $NVM_DIR/nvm.sh ]] && source "$NVM_DIR/nvm.sh"
  [[ -s $NVM_DIR/bash_completion ]] && source "$NVM_DIR/bash_completion"
}
for _cmd in nvm node npm npx; do
  eval "$_cmd() { _nvm_load; $_cmd \"\$@\"; }"
done
unset _cmd

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
[[ -r "$HOME/.config/zsh/sensei-dev.zsh" ]] && source "$HOME/.config/zsh/sensei-dev.zsh"

# Prompt
source ~/.config/zsh/prompt.zsh

# --- Aliases ---------------------------------------------------------------------
alias zshconfig="nvim ~/.zshrc"
alias reload="exec zsh"
alias e="nvim"
alias ls="lsd"
alias lsn="ls -ld *(/om[1])"
alias cls="clear"
alias cd="z"
alias lines="tokei"
alias get="sudo pacman -S"
alias yeet="sudo pacman -R"
alias updb="sudo pacman -Sy"
alias sizeof="sudo du -sh"
alias ':q'='exit'
alias ':Q'='exit'
alias py="python3"
alias srh="rga"
alias search="rga-fzf"
alias rm="trash"
alias pt="btop"
alias t="tmux attach -t daily_dev"
alias tc="tmux new -s daily_dev"
alias md="mkdir"
alias gc="git clone"
alias bt="sudo modprobe -r btusb && sudo modprobe btusb"
alias cameras="v4l2-ctl --list-devices"
alias init_venv="python3 -m venv"
alias init_venv_sys="python3 -m venv --system-site-packages"
alias homie="claude"
alias dt="distrobox-tui"
alias auv="distrobox enter auv-ros2"
alias auv-run="distrobox run --name auv-ros2 --"

# --- Functions -----------------------------------------------------------------
# Extract any common archive by extension.
ex() {
  [[ -f $1 ]] || { echo "'$1' is not a valid file"; return 1; }
  case $1 in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xf "$1" ;;
    *.tar.zst)        unzstd "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.zip)            unzip "$1" ;;
    *.Z)              uncompress "$1" ;;
    *.7z)             7z x "$1" ;;
    *.deb)            ar x "$1" ;;
    *)                echo "'$1' cannot be extracted via ex()"; return 1 ;;
  esac
}

# Pick a command from fzf and run it (used with a query: run 'pattern').
run() { echo | fzf -q "$*" --preview-window=up:99% --preview='eval {q}'; }

# Start a command detached from the terminal.
launch() { nohup "$@" >/dev/null 2>&1 & disown; }

# Ask tgpt a question in one line.
h() { tgpt "\"$*\""; }
