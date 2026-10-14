# Quiet two-line engineering prompt. No filled badges or external timing jobs.
export VIRTUAL_ENV_DISABLE_PROMPT=1 CONDA_CHANGEPS1=false
setopt PROMPT_SUBST
zmodload zsh/datetime
autoload -Uz add-zsh-hook
[[ -r ~/.config/zsh/sensei-palette.zsh ]] && source ~/.config/zsh/sensei-palette.zsh
# Detect the toolkit once per shell, not on every prompt.
if [[ -z ${SENSEI_CUDA_VERSION-} ]] && (( $+commands[nvcc] )); then
    local_version=$(command nvcc --version 2>/dev/null)
    [[ $local_version =~ 'release ([0-9]+\.[0-9]+)' ]] && SENSEI_CUDA_VERSION=$match[1]
    unset local_version
fi
# Retire only the functions supplied by the previous version of this file.
[[ ${functions[precmd]-} == *last_exit_code* ]] && unfunction precmd
[[ ${functions[preexec]-} == *timer=* ]] && unfunction preexec

_sensei_prompt_start() { _sensei_started=$EPOCHREALTIME; }
_sensei_prompt_refresh() {
    local result=$? elapsed=0 context='' branch='' location=${PWD/#$HOME/~}
    local paper=${WHITE:-'%F{#e8e2da}'} accent=${BLUE:-'%F{#f23d70}'} dim='%F{#9b9290}'
    if [[ -n ${_sensei_started-} ]]; then
        elapsed=$(( EPOCHREALTIME - _sensei_started ))
        unset _sensei_started
    fi
    local limit=$(( COLUMNS * 45 / 100 ))
    (( limit < 20 )) && limit=20
    (( limit > 70 )) && limit=70
    (( ${#location} > limit )) && location="…${location[-$((limit-1)),-1]}"
    location=${location//\%/%%}
    if [[ -n ${CONTAINER_ID-} ]]; then
        local container_name=$CONTAINER_ID line
        if [[ -r /run/.containerenv ]]; then
            while IFS= read -r line; do
                [[ $line == name=\"* ]] && container_name=${${line#name=\"}%\"}
            done </run/.containerenv
        fi
        context="box ${container_name//\%/%%}"
    fi
    local env_name=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:t}}
    [[ -n $env_name ]] && context+="${context:+  ·  }py ${env_name//\%/%%}"
    [[ -n ${ROS_DISTRO-} ]] && context+="${context:+  ·  }ROS ${ROS_DISTRO//\%/%%}"
    [[ -n ${SENSEI_CUDA_VERSION-} ]] && context+="${context:+  ·  }CUDA $SENSEI_CUDA_VERSION"
    branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    [[ -n $branch ]] && branch="  ${dim}git ${accent}${branch//\%/%%}%f"
    _sensei_left=$'\n'
    [[ -n $context ]] && _sensei_left+="  ${dim}${context}%f"$'\n'
    _sensei_left+="  ${dim}${location}%f${branch}"$'\n'
    _sensei_left+="  ${accent}%(#.#.❯)%f "
    _sensei_right="${dim}exit ${result}%f"
    (( result != 0 )) && _sensei_right="${accent}exit ${result}%f"
    local duration
    if (( elapsed >= 60 )); then
        local whole; printf -v whole '%d' "$elapsed"
        duration="$(( whole / 60 ))m $(( whole % 60 ))s"
    elif (( elapsed < 1 )); then printf -v duration '%.0fms' "$(( elapsed * 1000 ))"
    else printf -v duration '%.1fs' "$elapsed"; fi
    _sensei_right+="  ${dim}${duration}%f"
    [[ -n ${TMUX-} ]] && _sensei_right="${dim}tmux%f  ${_sensei_right}"
}
# Idempotent when the config is sourced again; preserve unrelated hooks.
add-zsh-hook -d preexec _sensei_prompt_start
add-zsh-hook -d precmd _sensei_prompt_refresh
add-zsh-hook preexec _sensei_prompt_start
add-zsh-hook precmd _sensei_prompt_refresh
PROMPT='${_sensei_left}'
RPROMPT='${_sensei_right}'
PS2="${BLUE:-'%F{#f23d70}'}… %f"
_sensei_prompt_refresh
