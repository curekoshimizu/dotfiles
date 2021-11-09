
# Add completion files
fpath=($HOME/.zsh-completions/src $fpath)
fpath=($HOME/.zfunc $fpath)

## NOTE: if you want to enable bazel zsh completion
## please read
##   https://docs.bazel.build/versions/master/completion.html
##   copy this script to $HOME/.zsh-completions/src


fadd() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf-tmux --multi --exit-0 --expect=ctrl-d); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      git diff --color=always $addfiles | less -R
    else
      git add $addfiles
    fi
  done
}


# git alias
function git-hash(){                                    
    git log --date=short --pretty='format:%h %cd %an%d %s' --graph --all | peco | sed -e 's/\([0-9a-f]\+\).\+$/\1/' | awk -F ' ' '{print $NF}'
}                                                       
function git-branch() {
    git branch -a | peco --prompt "GIT BRANCH>" | head -n 1  | tr -d " " | tr -d "*"
}

alias dc='docker-compose'
alias gtar='tar'
alias gmake='make'

case "${OSTYPE}" in
darwin*)
  alias ls="ls -G"
  alias ll="ls -lG"
  alias la="ls -laG"
  alias ltr='ls -ltrG'
  ;;
linux*)
  alias ls='ls --color'
  alias ll='ls -l --color'
  alias la='ls -la --color'
  alias ltr='ls -ltr --color'
  ;;
esac
alias duh='du -b | sort -n | numfmt --to=iec --suffix=B --padding=5'

alias -g H='$(git-hash)'
alias -g B='$(git-branch)'

# alias tree='tree -C'

# less alias
alias -g L='| less -r -F'

# to SJIS
alias -g S='| iconv -f SJIS'

# peco alias
alias -g P='| peco '

function peco-kill(){
    ps aux | peco | awk '{print $2}' | xargs kill -KILL
}

alias kill-peco="peco-kill"


# PROMPT
autoload -U colors
colors

case `hostname` in
    ajimejilo )
        _prompt_main_color=cyan
        ;;
    thinkpad )
        _prompt_main_color=cyan
        ;;
    curekoshimizu )
        _prompt_main_color=cyan
        ;;
    koshimizu )
        _prompt_main_color=magenta
        ;;
    * )
        _prompt_main_color=yellow
        ;;
esac

PROMPT="[%{${fg[${_prompt_main_color}]}%}%n@%m%{${fg[default]}%} %.]%{%(?.$fg[green].$fg_bold[red])%} %(?!+!-)%{${fg_no_bold[default]}%} %# "

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
#zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}(exist added files)"
#zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}(not add files)"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
RPROMPT='${vcs_info_msg_0_}'

setopt transient_rprompt # only last line will be used for right prompt status because of prevent from copy and paste

# HISTORY
HISTFILE=~/.zhistory
HISTSIZE=50000
SAVEHIST=50000

setopt hist_no_store
setopt histignoredups
setopt hist_reduce_blanks
setopt hist_ignore_space
setopt share_history
setopt extended_history

# bindkey "^P" history-beginning-search-backward
# bindkey "^N" history-beginning-search-forward
bindkey "^P" history-beginning-search-backward
bindkey "^N" history-beginning-search-forward
bindkey "^p" history-beginning-search-backward
bindkey "^n" history-beginning-search-forward

# MASK
umask 022

# KEY_BIND
bindkey -e


# OPTION
autoload -U compinit
compinit -u

setopt NUMERIC_GLOB_SORT
setopt NULL_GLOB

setopt LIST_PACKED
setopt LIST_ROWS_FIRST

#setopt CORRECT_ALL

unsetopt FLOW_CONTROL
#setopt IGNORE_EOF

setopt AUTO_PUSHD
setopt auto_cd

setopt nolistbeep

export LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35"

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' menu select=1

# cdr Settings
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 5000
zstyle ':chpwd:*' recent-dirs-default yes
zstyle ':completion:*' recent-dirs-insert both


zz() {
  if [[ -z "$*" ]]; then
    cd "$(_z -l 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
  else
    _last_z_args="$@"
    _z "$@"
  fi
}


# peco Settings
function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(\history -n 1 | \
        eval $tac | \
        peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

function peco-z-search
{
  which peco z > /dev/null
  if [ $? -ne 0 ]; then
    echo "Please install peco and z"
    return 1
  fi
  local res=$(z | sort -rn | cut -c 12- | peco)
  if [ -n "$res" ]; then
    BUFFER+="cd $res"
    zle accept-line
  else
    return 1
  fi
}
# zle -N peco-z-search
# bindkey '^g' peco-z-search
zle -N zz
bindkey '^g' zz
#alias cdp=peco-z-search
alias cdp='echo "please use ctrl-g."'

## z
Z_FILE=$(cd $(dirname $0); pwd)/.z/z.sh
source $Z_FILE

## direnv
export EDITOR=vim
if which direnv 2>&1 >/dev/null; then
    eval "$(direnv hook zsh)"
    alias tmux='direnv exec / tmux'
fi

# minikube
if command -v minikube 1>/dev/null 2>&1; then
    source <(minikube completion zsh) # for zsh users
fi
