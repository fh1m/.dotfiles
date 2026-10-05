# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# EXPORTS go brr

LS_COLORS='rs=0:di=1;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=0;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*.rasi=1;33';
export LS_COLORS
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Set name of the theme to load --- if set to "random", it will
ZSH_THEME=""
# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="mm/dd/yyyy"
# Skip compaudit's insecure-directory scan on every startup (compinit/compaudit
# accounted for a large chunk of shell startup time, measured via zprof).
ZSH_DISABLE_COMPFIX="true"
# Which plugins would you like to load?
plugins=(git sudo fzf fzf-tab zsh-lazyload zsh-autosuggestions zsh-syntax-highlighting shrink-path)
source $ZSH/oh-my-zsh.sh
# User configuration
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# GO
export PATH=$PATH:/usr/local/go/bin


# MISC
export PATH="$PATH:/home/fh1m/.local/bin"
export KEYTIMEOUT=1
export FZF_BASE=/usr/share/doc/fzf/examples
export FZF_DEFAULT_COMMAND='fd --type file --hidden --no-ignore --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 80% --layout=reverse --prompt="❱ "'
[[ -r ~/.config/fzf/sensei-colors ]] && export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(<~/.config/fzf/sensei-colors)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
alias zshconfig="nvim ~/.zshrc"
alias ls="lsd"
alias e="nvim"
alias lsn="ls -ld *(/om[1])"
alias cls="clear"
alias cd="z"
alias s="ncmpcpp -q"
alias ss="rmpc"
alias lines="tokei"
alias get="sudo pacman -S"
alias yeet="sudo pacman -R"
alias updb="sudo pacman -Sy"
alias space="diskonaut"
alias watch="hwatch"
alias bench="hyperfine"
alias sizeof="sudo du -sh"
alias ':q'='exit'
alias ':Q'='exit'
alias fileinfo="exiftool"
alias hex="hexyl"
alias py="python3"
alias srh="rga"
alias search="rga-fzf"
alias ping="gping"
alias rm="trash"
alias pt="btop"
alias t="tmux attach -t daily_dev"
alias tc="tmux new -s daily_dev"
alias tk="tmux kill-server"
alias md="mkdir"
alias gc="git clone"
alias band="sudo ~/.cargo/bin/bandwhich"
alias reload="exec zsh"
alias bt="sudo modprobe -r btusb && sudo modprobe btusb"
alias cameras="v4l2-ctl --list-devices"
alias init_venv="python3 -m venv"
alias init_venv_sys="python3 -m venv --system-site-packages"
alias homie="claude"

# ROS 2 [Humble]
if [[ -f /opt/ros/humble/setup.zsh ]]; then
  source /opt/ros/humble/setup.zsh
  # Source local workspace overlay if built
  [[ -f ~/ros2_ws/install/setup.zsh ]] && source ~/ros2_ws/install/setup.zsh
  # Match container DDS config so host↔container nodes discover each other
  export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
  export ROS_DOMAIN_ID=42
  export ROS_LOCALHOST_ONLY=0
fi

# Gazebo 11
# source /usr/share/gazebo/setup.sh
# source /usr/share/gazebo-11/setup.sh


# Rust build cache (speeds up repeated cargo builds across projects)
export RUSTC_WRAPPER=sccache

# CUDA ENV config (Arch: /opt/cuda symlink managed by cuda package)
export CUDA_INSTALL_PATH=/opt/cuda
export CUDA_HOME=$CUDA_INSTALL_PATH
export CUDA_LIB_PATH=$CUDA_INSTALL_PATH/lib64
export CUDA_BIN_PATH=$CUDA_INSTALL_PATH/bin
export LD_LIBRARY_PATH=$CUDA_LIB_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$CUDA_BIN_PATH${PATH:+:${PATH}}

# Funcctions
function tmux_session_switch() {
  session=$(tmux list-windows -a | fzf | sed 's/: .*//g')
  tmux switch-client -t "$session"
}


function tmux_kill_uname_session() {
  echo "kill all unname tmux session"
  cd /tmp/
  tmux ls | awk '{print $1}' | grep -o '[0-9]\+' >/tmp/killAllUnnameTmuxSessionOutput.sh
  sed -i 's/^/tmux kill-session -t /' killAllUnnameTmuxSessionOutput.sh
  chmod +x killAllUnnameTmuxSessionOutput.sh
  ./killAllUnnameTmuxSessionOutput.sh
  cd -
  tmux ls
}

# launch without text
function launch {
    nohup "$@" >/dev/null 2>/dev/null & disown
}

# Keybinds
bindkey '^[r' fzf-history-widget

# Stuff thats needs starting
eval "$(zoxide init zsh)" # magic cd

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
export NVM_DIR="$HOME/.nvm"
# Lazy-loaded via zsh-lazyload (see plugins=) instead of sourcing nvm.sh directly at shell startup.
# nvm_auto accounted for ~55-84% of shell startup time (measured via zprof).
lazyload nvm node npm npx -- '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

# FZF love  BUG: stops fzf-tab from wroking, so no needed.
#----------
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Prompt
if [[ -f ~/.config/zsh/prompt.zsh ]]; then
    source ~/.config/zsh/prompt.zsh
else
    echo "Warning: Prompt configuration file not found at ~/.config/zsh/prompt.zsh"
fi

# Extract
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

function run(){
echo | fzf -q "$*" --preview-window=up:99% --preview="eval {q}"
}

h() {
  tgpt "\"$*\""
}

export DBX_CONTAINER_MANAGER=docker
export PATH="$PATH:/home/fh1m/go/bin"

# Distrobox
alias dt="distrobox-tui"
alias auv="distrobox enter auv-ros2"
alias auv-run="distrobox run --name auv-ros2 --"


# conda init block removed: /home/fh1m/Envs/conda no longer exists (dead
# subprocess call on every shell startup). uv is the active Python manager.


export PATH=$PATH:/home/fh1m/.spicetify
# Pyenv
# export PYENV_ROOT="/home/fh1m/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init - zsh)"

alias claude-mem='bun "/home/fh1m/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'


# Added by Antigravity CLI installer
export PATH="/home/fh1m/.local/bin:$PATH"
