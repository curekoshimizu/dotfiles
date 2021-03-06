export LANG=ja_JP.UTF-8

typeset -U path PATH
export FZF_DEFAULT_OPTS='--bind ctrl-n:down,ctrl-p:up'

## ------------------------------------------------
## PATH Settings
## -----------------------------------------------
## Basic PATH
PATH=/usr/local/bin:$PATH
PATH=$PATH:/sbin:/usr/bin:/bin:$HOME/bin
PATH=$PATH:$HOME/.poetry/bin
## Mac Brew Settings (coreutils)
#case ${OSTYPE} in
#    darwin*)
#        PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
#        PATH=/usr/local/texlive/2014/bin/x86_64-darwin:$PATH
#        ;;
#esac

## Golang
if [ -d ${HOME}/.golang ]; then
    export PATH=$PATH:$HOME/.golang/bin
fi

## RUST
if [ -d ${HOME}/.cargo/env ];
    then source ${HOME}/.cargo/env;
fi

# pyenv
PYENV_ROOT="$HOME/.pyenv"
if [ -d ${PYENV_ROOT} ]; then
    export PYENV_ROOT
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

NVM_DIR="$HOME/.nvm"
if [ -d ${NVM_DIR} ]; then
    export NVM_DIR
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# unused because I started to use nvm
# # NPM
# # ref. https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
# NPM_CONFIG_PREFIX=$HOME/.npm-global
# PATH=${NPM_CONFIG_PREFIX}/bin:$PATH

## Java Settings
#export JAVA_HOME=/usr/java/default


##===================================================================
#
## ------------------------------------------------
## LD_LIBRARY_PATH Settings
## -----------------------------------------------
## BASIC LIB PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib
## HOME LIB PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/install/bin
##=====================================================================
#
## ------------------------------------------------
## PKG_CONFIG_PATH Settings
## -----------------------------------------------
## Basic PKG
PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/lib/pkgconfig:/usr/local/lib/pkgconfig
##=====================================================================
#
export PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
