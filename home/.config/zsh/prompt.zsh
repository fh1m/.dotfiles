# Custom Zsh Prompt Configuration
# Add this to your ~/.config/zsh/prompt.zsh file

# Disable default virtual environment prompt display
export VIRTUAL_ENV_DISABLE_PROMPT=1
export CONDA_CHANGEPS1=false

# Enable prompt substitution
setopt PROMPT_SUBST

# Color definitions
autoload -U colors && colors
BLUE="%{$fg[blue]%}"
GREEN="%{$fg[green]%}"
YELLOW="%{$fg[yellow]%}"
RED="%{$fg[red]%}"
CYAN="%{$fg[cyan]%}"
MAGENTA="%{$fg[magenta]%}"
WHITE="%{$fg[white]%}"
RESET="%{$reset_color%}"
[[ -r ~/.config/zsh/sensei-palette.zsh ]] && source ~/.config/zsh/sensei-palette.zsh

# Variables to store command execution info
last_exit_code=""
last_time=""

# Function to get git branch
git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n $branch ]]; then
        echo "${YELLOW}(${branch})${RESET}"
    fi
}

# Function to detect virtual environment and Python version (COMBINED)
venv_info() {
    local env_name=""
    local py_version=""
    local combined_info=""

    # Get Python version if in virtual environment
    if [[ -n $CONDA_DEFAULT_ENV || -n $VIRTUAL_ENV || -n $PIPENV_ACTIVE ]]; then
        py_version=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    fi

    # Check for conda environment
    if [[ -n $CONDA_DEFAULT_ENV ]]; then
        env_name="conda:$CONDA_DEFAULT_ENV"
    # Check for virtual environment
    elif [[ -n $VIRTUAL_ENV ]]; then
        env_name="venv:$(basename $VIRTUAL_ENV)"
    # Check for pipenv
    elif [[ -n $PIPENV_ACTIVE ]]; then
        env_name="pipenv"
    fi

    # Combine environment and Python version
    if [[ -n $env_name ]]; then
        combined_info="in ${env_name}"
        if [[ -n $py_version ]]; then
            combined_info="${combined_info}, using py${py_version}"
        fi
        echo "${GREEN}(${combined_info})${RESET}"
    fi
}

# Function to detect ROS version
ros_info() {
    if [[ -n $ROS_DISTRO ]]; then
        echo "${MAGENTA}(using ROS_${ROS_DISTRO})${RESET}"
    fi
}

# Function to detect CUDA version
cuda_info() {
    if [[ -n $SENSEI_CUDA_VERSION ]]; then
        local cuda_version=$SENSEI_CUDA_VERSION
        if [[ -n $cuda_version ]]; then
            echo "${CYAN}[on cuda ${cuda_version}]${RESET}"
        fi
    elif [[ -f /usr/local/cuda/version.txt ]]; then
        local cuda_version=$(cat /usr/local/cuda/version.txt | grep "CUDA Version" | sed 's/.*CUDA Version \([0-9]\+\.[0-9]\+\).*/\1/')
        if [[ -n $cuda_version ]]; then
            echo "${CYAN}[on cuda ${cuda_version}]${RESET}"
        fi
    fi
}

# The toolkit version cannot change inside a shell; do not spawn nvcc on
# every prompt redraw. This was visible as terminal latency after commands.
if command -v nvcc >/dev/null 2>&1; then
    SENSEI_CUDA_VERSION=$(nvcc --version 2>/dev/null | sed -n 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/p')
fi

# Function to detect distrobox container
# Distrobox sets CONTAINER_ID in every managed container.
# We read the container name from /run/.containerenv (Docker)
# or fall back to CONTAINER_ID. Shows nothing on the host.
distrobox_info() {
    # Quick bail — not inside any container
    [[ -z $CONTAINER_ID ]] && return

    local cname=""

    # Docker: distrobox writes the container name into /run/.containerenv
    if [[ -f /run/.containerenv ]]; then
        cname=$(grep -oP '^name="\K[^"]+' /run/.containerenv 2>/dev/null)
    fi

    # Fallback to the env var distrobox always exports
    [[ -z $cname ]] && cname="$CONTAINER_ID"

    if [[ -n $cname ]]; then
        echo "${RED}[Inside Docker: ${cname}]${RESET}"
    fi
}

# Function to get truncated current directory
current_dir() {
    local dir="$PWD"
    local home="$HOME"

    # Replace home directory with ~
    if [[ "$dir" == "$home" ]]; then
        dir="~"
    elif [[ "$dir" == "$home"/* ]]; then
        dir="~${dir#$home}"
    fi

    # Truncate if too long (you can adjust the length)
    local max_length=34
    if [[ ${#dir} -gt $max_length ]]; then
        dir="…${dir: -$((max_length-1))}"
    fi

    echo "$dir"
}

# Function to track command execution time and exit code
preexec() {
    timer=$(($(date +%s%0N)/1000000))
}

precmd() {
    # Capture the exit code FIRST before any other commands
    last_exit_code=$?

    if [ $timer ]; then
        local now=$(($(date +%s%0N)/1000000))
        local elapsed=$(($now-$timer))

        # Convert to appropriate time format
        if [[ $elapsed -gt 60000 ]]; then
            last_time="$((elapsed/1000))s"
        elif [[ $elapsed -gt 1000 ]]; then
            last_time="$((elapsed/1000))s"
        else
            last_time="${elapsed}ms"
        fi

        unset timer
    fi
}

# Function to show command result info (right side of prompt)
command_info() {
    if [[ -n $last_exit_code ]] && [[ -n $last_time ]]; then
        local exit_color
        if [[ $last_exit_code -eq 0 ]]; then
            exit_color=$GREEN
        else
            exit_color=$RED
        fi
        echo "${exit_color}exited with ${last_exit_code}${RESET}, took ${CYAN}${last_time}${RESET}"
    fi
}

# Function to build environment info line
env_info_line() {
    local git_info="$(git_branch)"
    local venv_info="$(venv_info)"
    local ros_info="$(ros_info)"
    local cuda_info="$(cuda_info)"
    local distrobox_info="$(distrobox_info)"

    # Build left side (CUDA, Distrobox, ROS — in that order)
    local left_side=""
    [[ -n $cuda_info ]] && left_side="$left_side$cuda_info "
    [[ -n $distrobox_info ]] && left_side="$left_side$distrobox_info "
    [[ -n $ros_info ]] && left_side="$left_side$ros_info"

    # Build right side (venv and git)
    local right_side=""
    [[ -n $venv_info ]] && right_side="$right_side$venv_info"
    [[ -n $git_info ]] && right_side=" $git_info$right_side"

    # Only show the line if we have environment info
    if [[ -n $left_side || -n $right_side ]]; then
        # Calculate spacing to push right_side to the right
        local term_width=${COLUMNS:-80}
        local left_length=${#${(S%%)left_side//$~%([BSUbfksu]|([FB]|){*})/}}
        local right_length=${#${(S%%)right_side//$~%([BSUbfksu]|([FB]|){*})/}}
        local spaces=$((term_width - left_length - right_length))

        # Ensure minimum spacing
        if [[ $spaces -lt 1 ]]; then
            spaces=1
        fi

        local spacing=""
        for ((i=1; i<=spaces; i++)); do
            spacing+=" "
        done

        echo "${left_side}${spacing}${right_side}"
    fi
}

# Main prompt function
build_prompt() {
    local env_line="$(env_info_line)"
    local dir_info="${BADGE} 󰆍  $(current_dir) ${BADGE_END} ${BLUE}❯${RESET}"

    # Build the full prompt
    if [[ -n $env_line ]]; then
        echo "${env_line}"
        echo "${dir_info} "
    else
        echo "${dir_info} "
    fi
}

# Set the prompt with command info on the right
PROMPT='$(build_prompt)'
RPROMPT='$(command_info)'

# Optional: Customize the continuation prompt
PS2="${BLUE}> ${RESET}"
