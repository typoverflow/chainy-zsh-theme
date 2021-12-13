#! /usr/local/env zsh

# set -x

FILE_DIR="$(pwd)/"
ALL_BLOCKS_ARRAY=(
    ip \
    path \
    git \
    conda \
)
ALL_BLOCKS="${ALL_BLOCKS_ARRAY[@]}"

# <<<<<<< function >>>>>>>>
function block_msg() {
    echo "script usage:"
    echo "This is a generator for chainy-zsh-theme. Specify the blocks you wish to present in PS1, and this script will generate corresponding file."
    echo "Supported blocks are:"
    echo "  ip     : ip address"
    echo "  path   : current working directory"
    echo "  git    : git statues"
    echo "  conda  : current conda environment"
}

while getopts 'ld:' OPTION; do
    case "$OPTION" in 
        d)
            if [[ OPTARG =~ [^/]$ ]]; then
                FILE_DIR="`pwd`/${OPTARG}/"
            else
                FILE_DIR="`pwd`/${OPTARG}"
            fi
            ;;
        l)
            block_msg
            exit 0
            ;;
        ?)
            echo "Unrecognized option." && exit 1
            ;;
    esac
done
shift "$(( $OPTIND -1 ))"

if [[ ! -d FILE_DIR ]]; then
    mkdir -p ${FILE_DIR}
fi

FILE_PATH="${FILE_DIR}chainy.zsh-theme"

if [[ -f ${FILE_PATH} ]]; then
    echo "There exists a chainy theme file in target directory. "
    echo "Type 'yes' to proceed and 'no' to abort"
    while (( 1 )); do
        read
        case $REPLY in
            [Yy]es )
                echo "Overiding ..."
                break
                ;;
            [Nn]o )
                echo "Abort." && exit 1
                ;;
            * )
                echo "Unrecognized answer."
                ;;
        esac
    done
fi

# <<<<<<< contents >>>>>>>>
top_left='${c_dash}╭─${c_reset}'
for block in "$@"; do
  if [[ ! $ALL_BLOCKS =~ "\\b${block}\\b" ]];then
    echo "Unrecognized block name ${block}";
    continue;
  else
    top_left+='${'"${block}"'_info}'
  fi
done

CODE='
# define colors and icons
c_reset="%{$reset_color%}"
c_dash="$FG[242]"
c_dir="%{$terminfo[bold]$FG[114]%}"
SEP="${c_dash}─${c_reset}"
c_git="%{$terminfo[bold]$FG[144]%}"
c_sha="%{$terminfo[bold]$FG[110]%}"
c_conda="%{$terminfo[bold]$FG[105]%}"
c_correct="%{$FG[150]%}"
c_wrong="%{$FG[202]%}"
c_ip="%{$terminfo[bold]$FG[069]%}"
# icons
i_correct="▶"
i_wrong="▶"

# necessary functions
function prompt-length() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  typeset -g REPLY=$x
}

function fill-line() {
  emulate -L zsh
  prompt-length $1
  local -i left_len=REPLY
  prompt-length $2 9999
  local -i right_len=REPLY
  local -i pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-0}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    typeset -g REPLY=$1
  else
    local pad=${(pl.$pad_len..─.)}  # pad_len spaces
    typeset -g REPLY=${1}${c_dash}${pad}${c_reset}${2}
  fi
}

# get conda
function conda_prompt_info() {
	if [ -n "$CONDA_DEFAULT_ENV" ]; then
		echo -n "$SEP${c_conda}[\uf10c $CONDA_DEFAULT_ENV]${c_reset}"
	else
		echo -n ""
	fi
}

# get ip
function ip_prompt_info() {
	local ip="$(ip a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '\''{print $2}'\'' | awk -F "/" '\''{print $1}'\'' | head -n 1)"
	if [ ! -z ${ip} ]; then
		echo -n "$SEP${c_ip}[\ue764 ${ip}]${c_reset}"
	else
		echo -n ""
	fi
}

# Git info
ZSH_THEME_GIT_PROMPT_PREFIX="$SEP${c_git}[\ue702 "
ZSH_THEME_GIT_PROMPT_SUFFIX="${c_git}]${c_reset}"
ZSH_THEME_GIT_PROMPT_DIRTY="${c_wrong}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="${c_correct}●"

# main
function set-prompt() {
  emulate -L zsh
  local path_info="${SEP}${c_dir}[${PWD/#$HOME/~}]${c_reset}"
  local git_info="$(git_prompt_info)"
  local conda_info="$(conda_prompt_info)"
  local ip_info="$(ip_prompt_info)"

  local top_left="'"${top_left}"'"

  local top_right="${c_dash} %T %n@%m${c_reset}"
  local bottom_left="${c_dash}╰─${c_reset}%(?:${c_correct}${i_correct} :${c_wrong}${i_wrong} )${c_reset}"

  local REPLY
  fill-line "$top_left" "$top_right"

  PROMPT=$REPLY$'\''\\n'\''$bottom_left
}

setopt no_prompt_{bang,subst} prompt_{cr,percent,sp}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-prompt
'

echo ${CODE} > ${FILE_PATH}
echo "Generated chainy.zsh-theme in ${FILE_DIR}"
