# Add completion files
fpath=($HOME/.zsh-completions/src $fpath)
fpath=($HOME/.zfunc $fpath)

## NOTE: if you want to enable bazel zsh completion
## please read
##   https://docs.bazel.build/versions/master/completion.html
##   copy this script to $HOME/.zsh-completions/src


# for aws command
AWS_COMPLETER_PATH=$(which aws_completer)
# Check if aws_completer exists and is executable
if [ -n "$AWS_COMPLETER_PATH" ] && [ -x "$AWS_COMPLETER_PATH" ]; then
  autoload bashcompinit && bashcompinit
  autoload -Uz compinit
  compinit
  complete -C "$AWS_COMPLETER_PATH" aws
fi


# git alias
function git-branch() {
    git branch | peco --prompt "GIT BRANCH>" | head -n 1  | tr -d " " | tr -d "*"
}
function git-changed-files(){
  git status --short | peco | awk '{print $2}'
}

alias dc='docker-compose'
alias gtar='tar'
alias gmake='make'
alias ip='ip --color=auto'
alias vim-tiny='vim -u NONE -N'

case "${OSTYPE}" in
darwin*)
  alias ls="ls -G"
  alias ll="ls -lG"
  alias la="ls -laG"
  alias ltr='ls -ltrG'
  if ! sed --version > /dev/null 2>&1; then
      # sed is not GNU sed.
      # How to install GNU sed -- brew install gnu-sed.
      alias sed="gsed"
  fi
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  ;;
linux*)
  alias ls='ls --color'
  alias ll='ls -l --color'
  alias la='ls -la --color'
  alias ltr='ls -ltr --color'
  alias ipa='ip -br -c a'

  # minikubeではなくkindをつかってみることに
  # if command -v minikube >/dev/null 2>&1; then
  #   alias kubectl="minikube kubectl --"
  # fi
  # minikube
  # 自動補完がうまくうごかないときがあるのでOFFにしたが動くようになっているかもしれない
  # if command -v minikube >/dev/null 2>&1; then
  #     source <(minikube completion zsh) # for zsh users
  # fi

  ;;
esac
alias duh='du -b | sort -n | numfmt --to=iec --suffix=B --padding=5'

alias -g B='$(git-branch)'
alias -g F='$(git-changed-files)'

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
setopt nohashcmds

# refs: ehttps://www.pandanoir.info/entry/2024/04/27/165533
# コマンドラインをエディタで編集する関数
edit-command-line() {
  # 現在のコマンドラインを一時ファイルに書き出す
  local tmpfile=$(mktemp)
  print -rl -- $BUFFER > $tmpfile

  $EDITOR $tmpfile < /dev/tty

  # エディタが正常に終了した場合、一時ファイルの内容でコマンドラインを置き換え
  if [[ $? -eq 0 ]]; then
    BUFFER=$(<$tmpfile)
    zle reset-prompt
  fi

  rm -f $tmpfile
}


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

## uv
if which uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

## direnv
export EDITOR=vim
if which direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
    alias tmux='direnv exec / tmux'
fi

## mise
if which mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# gh
if which gh >/dev/null 2>&1; then
    eval "$(gh completion -s zsh)"
fi

# kubectl
alias k='kubectl'
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# # lazy load
# function lazy_load_nvm
# {
#     if [ -z ${NVM_LOADED} ]; then
#         # if use npm, nvm or vim, load NVM settings.
#         if [[ $1 = *"sls"* ]] || [[ $1 = *"npm"* ]] || [[ $1 = *"nvm"* ]] || [[ $1 = *"vim"* ]]; then
#             NVM_LOADED=1
#             load_nvm
#         fi
#     fi
# }
# autoload -Uz add-zsh-hook
# add-zsh-hook preexec  lazy_load_nvm

zle -N edit-command-line
bindkey "^O" edit-command-line


bindkey "^P" history-beginning-search-backward
bindkey "^N" history-beginning-search-forward


function git-make-worktree() {
  local b=$1
  [[ -z $b ]] && { echo "ブランチ名必須"; return 1; }

  # 既存 worktree かどうか調べる
  local d
  d=$(git worktree list --porcelain |
        awk -v br="$b" '
          /^worktree / {w=$2}
          $0=="branch refs/heads/"br {print w; exit}')

  # 無ければ作成
  if [[ -z $d ]]; then
    d=../${b//\//__}
    git worktree add -B "$b" "$d" "origin/$b" 2>/dev/null ||
    git worktree add -b "$b" "$d"
  fi

  cd "$d"
}

# Git Worktree ROOT へ移動
fucntion git-cd-root() {
  local root
  root=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
  cd "$root" || return
}

# Git Worktree Delete
function git-delete-worktree() {
  # --- 一覧取得（パスだけ） -------------------------------
  local paths
  paths=("${(@f)$(git worktree list --porcelain | awk '/^worktree /{print $2}')}")

  # メインワークツリー（先頭）を控えておく
  local root=${paths[1]}

  # --- fzf で選択 ----------------------------------------
  local target
  # メインを除外したリストで fzf（キャンセルで抜ける）
  target=$(printf '%s\n' "${paths[@]:1}" \
           | fzf --prompt='delete> ' --reverse) || return

  # --- 確認プロンプト ------------------------------------
  if ! read -q "yn?Remove ${target}? [y/N] "; then
    echo      # 改行
    echo 'Canceled.'
    return
  fi
  echo

  # --- 削除実行 ------------------------------------------
  git worktree remove --force "$target" || return
  git worktree prune
}
