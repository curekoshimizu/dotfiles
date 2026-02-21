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
  if [[ -z "$_COMPINIT_DONE" ]]; then
    compinit
    _COMPINIT_DONE=1
  fi
  complete -C "$AWS_COMPLETER_PATH" aws
fi


# git alias
function git-branch() {
    git branch | fzf --prompt "GIT BRANCH> " | head -n 1  | tr -d " " | tr -d "*"
}
function git-changed-files(){
  git status --short | fzf | awk '{print $2}'
}

alias dc='docker-compose'
alias gtar='tar'
alias gmake='make'
alias ip='ip --color=auto'
alias vim-tiny='vim -u NONE -N'

# python/pip エイリアス（既存コマンドがない場合のみ）
if ! command -v python >/dev/null 2>&1; then
  alias python=python3
fi
if ! command -v pip >/dev/null 2>&1; then
  alias pip=pip3
fi

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

# fzf alias
alias -g P='| fzf '

function fzf-kill(){
    ps aux | fzf | awk '{print $2}' | xargs kill -KILL
}

alias kill-peco="fzf-kill"


# PROMPT — Powerline Ocean style (ホスト名で色パレットを切替)
autoload -U colors
colors

# 色パレット: c1(暗)=時刻, c2(中)=host, c3(明)=ディレクトリ
# user@hostname のハッシュから自動決定。~/.prompt_override で番号指定可
_prompt_palettes=(
    "22 34 42"     #  1: Forest
    "23 30 37"     #  2: Teal
    "25 61 67"     #  3: Petrol
    "53 141 183"   #  4: Purple
    "54 97 140"    #  5: Indigo
    "58 108 150"   #  6: Slate
    "88 160 203"   #  7: Crimson
    "94 132 175"   #  8: Plum
    "100 136 172"  #  9: Copper
    "125 168 211"  # 10: Rose
    "130 208 214"  # 11: Orange
    "22 71 114"    # 12: Emerald
    "52 90 133"    # 13: Grape
    "58 166 209"   # 14: Moss
    "24 33 39"     # 15: Ocean (blue) ← shugo@shugolaptop
)

# _apply_prompt_palette: パレット番号からPROMPTを即時反映
_apply_prompt_palette() {
    _prompt_idx=$1
    read _pc1 _pc2 _pc3 <<< "${_prompt_palettes[$_prompt_idx]}"
    local a=$'\ue0b0'
    PROMPT="%F{15}%K{${_pc1}} %* %F{${_pc1}}%K{${_pc2}}${a}%F{15} %n@%m %F{${_pc2}}%K{${_pc3}}${a}%F{15} %. %k%F{${_pc3}}${a}%f "
}

# パレット決定: ~/.prompt_override があればその番号、なければ user@host のハッシュ
if [[ -f ~/.prompt_override ]] && (( $(cat ~/.prompt_override) >= 1 )) && (( $(cat ~/.prompt_override) <= ${#_prompt_palettes[@]} )); then
    _apply_prompt_palette $(cat ~/.prompt_override)
else
    _apply_prompt_palette $(( $(echo "$(whoami)@$(hostname -s)" | cksum | cut -d' ' -f1) % ${#_prompt_palettes[@]} + 1 ))
fi

# prompt_test: 全パレットをプレビュー表示。prompt_test <番号> で固定＆即時反映
prompt_test() {
    local a=$'\ue0b0' i=1
    if [[ "$1" == "reset" ]]; then
        rm ~/.prompt_override
        _apply_prompt_palette $(( $(echo "$(whoami)@$(hostname -s)" | cksum | cut -d' ' -f1) % ${#_prompt_palettes[@]} + 1 ))
        echo "ハッシュ自動決定に戻しました（#${_prompt_idx}）"
        return
    fi
    if [[ -n "$1" ]] && (( $1 >= 1 )) && (( $1 <= ${#_prompt_palettes[@]} )); then
        echo "$1" > ~/.prompt_override
        _apply_prompt_palette "$1"
        echo "Palette #$1 に固定しました（prompt_test reset で解除）"
        return
    fi
    for p in "${_prompt_palettes[@]}"; do
        local c1 c2 c3
        read c1 c2 c3 <<< "$p"
        printf "%2d: \e[97;48;5;${c1}m %s \e[38;5;${c1};48;5;${c2}m${a}\e[97m %s \e[38;5;${c2};48;5;${c3}m${a}\e[97m %s \e[0;38;5;${c3}m${a}\e[0m" \
            "$i" "$(date +%T)" "$(whoami)@$(hostname -s)" "$(basename $PWD)"
        [[ $i -eq $_prompt_idx ]] && printf "  ← current"
        printf "\n"
        (( i++ ))
    done
}

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{yellow}'
zstyle ':vcs_info:git:*' unstagedstr '%F{red}'
zstyle ':vcs_info:*' formats '%c%u[%b]%f'
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
RPROMPT='${vcs_info_msg_0_}'

setopt transient_rprompt

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
# compinit（起動ごとに1回だけ実行）
autoload -U compinit
if [[ -z "$_COMPINIT_DONE" ]]; then
  compinit -u
  _COMPINIT_DONE=1
fi

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


# history search (fzf with timestamp display)
function select-history() {
    if command -v fzf > /dev/null; then
        # extended_history format: ": timestamp:duration;command"
        local selected
        selected=$(awk -F';' '/^: [0-9]+/{
            split($1, a, ":")
            ts = a[2]; sub(/^ /, "", ts)
            cmd = substr($0, index($0, ";") + 1)
            printf "%s\t%s\n", strftime("%Y-%m-%d %H:%M", ts), cmd
        }' "$HISTFILE" | tac | fzf --no-sort --query "$LBUFFER" \
            --delimiter='\t' --with-nth=1,2 \
            --tabstop=20)
        BUFFER=${selected#*	}
    elif command -v peco > /dev/null; then
        local tac
        if which tac > /dev/null; then
            tac="tac"
        else
            tac="tail -r"
        fi
        BUFFER=$(\history -n 1 | eval $tac | peco --query "$LBUFFER")
    fi
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N select-history
bindkey '^r' select-history

function fzf-z-search
{
  which fzf z > /dev/null
  if [ $? -ne 0 ]; then
    echo "Please install fzf and z"
    return 1
  fi
  local res=$(z | sort -rn | cut -c 12- | fzf)
  if [ -n "$res" ]; then
    BUFFER+="cd $res"
    zle accept-line
  else
    return 1
  fi
}
# zle -N fzf-z-search
# bindkey '^g' fzf-z-search
zle -N zz
bindkey '^g' zz
#alias cdp=fzf-z-search
alias cdp='echo "please use ctrl-g."'

## z
Z_FILE=$(cd $(dirname $0); pwd)/.z/z.sh
source $Z_FILE

## 補完キャッシュ用関数（1日1回再生成）
_COMP_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-completions-cache"
mkdir -p "$_COMP_CACHE_DIR"
_cached_completion() {
  local name="$1"
  local cmd="$2"
  local cache="$_COMP_CACHE_DIR/$name.zsh"
  # キャッシュが存在しないか、1日以上古い場合は再生成
  if [[ ! -f "$cache" ]] || [[ $(find "$cache" -mtime +1 2>/dev/null) ]]; then
    eval "$cmd" > "$cache" 2>/dev/null
  fi
  [[ -f "$cache" ]] && source "$cache"
}

## uv（遅延ロード）
_load_uv_completion() {
  unset -f uv
  _cached_completion "uv" "uv generate-shell-completion zsh"
}
if which uv >/dev/null 2>&1; then
  uv() { _load_uv_completion; command uv "$@"; }
fi

## direnv（完全遅延ロード - ディレクトリ変更時に初期化）
export EDITOR=vim
if which direnv >/dev/null 2>&1; then
    _load_direnv() {
      if [[ -z "$_DIRENV_LOADED" ]]; then
        eval "$(direnv hook zsh)"
        _DIRENV_LOADED=1
        # 初期化後に現在のディレクトリで.envrcを読み込む
        _direnv_hook
      fi
    }
    # ディレクトリ変更時に初期化
    chpwd_functions+=(_load_direnv)
    alias tmux='direnv exec / tmux'
fi

## mise
if which mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# gh
if which gh >/dev/null 2>&1; then
    _cached_completion "gh" "gh completion -s zsh"
fi

# kubectl（遅延ロード）
alias k='kubectl'
_load_kubectl_completion() {
  unalias kubectl 2>/dev/null
  unset -f kubectl
  _cached_completion "kubectl" "kubectl completion zsh"
}
if command -v kubectl >/dev/null 2>&1; then
  kubectl() { _load_kubectl_completion; command kubectl "$@"; }
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

gw() {
  # --- Git リポジトリか判定 -------------------------------------------------
  git rev-parse --is-inside-work-tree &>/dev/null || {
    echo "Not inside a Git repo"; return 1; }

  # --- 現在いる worktree（プライマリ）のルート ------------------------------
  local cur_wt
  cur_wt=$(git rev-parse --show-toplevel)

  # --- worktree 一覧を生成（現在位置は除外、作成日時順でソート）------------
  local list
  list=$(
    git worktree list --porcelain |
      awk -v CUR="$cur_wt" '
        /^worktree/ { wdir=$2 }
        /^branch/   { sub("refs/heads/","",$2); wbranch=$2 }
        /^$/ {
          if (wdir == CUR) next
          cmd = "stat -f %B \"" wdir "\" 2>/dev/null"
          if ((cmd | getline ts) > 0 && ts != "") {
            printf("%s\t%s\t%s\n", ts, wbranch ? wbranch : "(detached)", wdir)
          }
          close(cmd)
        }
      ' | sort -t$'\t' -k1,1rn |
      while IFS=$'\t' read -r ts branch dir; do
        date_str=$(LANG=ja_JP.UTF-8 date -r "$ts" "+%Y-%m-%d (%a) %H:%M" 2>/dev/null) || continue
        printf "%s\t%s\t%s\n" "$date_str" "$branch" "$dir"
      done
  )

  # --- fzf 起動 -------------------------------------------------------------
  local sel key
  sel=$(
    printf '%s\n' "$list" |
      fzf --ansi --height=40% --reverse \
          --prompt="Worktree> " \
          --expect=enter,ctrl-w,ctrl-x \
          --bind="ctrl-n:down,ctrl-p:up,ctrl-w:accept"
  ) || return
  key=${sel%%$'\n'*}           # 押下キー
  sel=${sel#*$'\n'}            # 選択行

  local _date branch wt_dir
  IFS=$'\t' read -r _date branch wt_dir <<< "$sel"

  # --- モード別処理 ---------------------------------------------------------
  case "$key" in
    enter|"")  # ---------- 切り替え ----------
      [ -n "$wt_dir" ] && cd "$wt_dir"
      ;;

    ctrl-w)    # ---------- 新規作成 (W = worktree) ----------
      # 1 つだけ聞く → ブランチ名＝作るディレクトリ名（basename）
      printf 'Worktree name/path [../<name>]: ' ; read -r new_dir || return
      [ -z "$new_dir" ] && { echo 'Canceled'; return; }

      # 相対名だけ渡されたら ../<name> に置く（ディレクトリを明示したければフルパスで入力）
      if [[ "$new_dir" != */* ]]; then
        new_dir="../$new_dir"
      fi
      local new_branch
      new_branch=$(basename "$new_dir")

      if git show-ref --verify --quiet "refs/heads/$new_branch"; then
        # 既存ブランチ → そのブランチで worktree を追加
        git worktree add "$new_dir" "$new_branch" || return
      else
        # 新規ブランチを切って worktree 追加
        git worktree add -b "$new_branch" "$new_dir" || return
      fi
      cd "$new_dir"
      ;;

    ctrl-x)    # ---------- 削除 ----------
      [ -z "$wt_dir" ] && { echo 'Nothing selected'; return 1; }
      if [ "$wt_dir" = "$cur_wt" ]; then
        echo 'Cannot remove primary worktree'; return 1
      fi
      printf "Remove worktree '%s'? [y/N] " "$wt_dir"
      read -r yn
      [[ "$yn" =~ ^[Yy]$ ]] || { echo 'Aborted'; return; }
      git worktree remove --force "$wt_dir" && git worktree prune
      ;;
  esac
}
\$() {
    claude "$*"
}


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
