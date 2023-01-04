#!/usr/bin/env bash

set -eu

if ! type python3 >/dev/null 2>&1; then
    echo "python3 not found."
    exit 1
fi

if ! python3 -m distutils.util >/dev/null 2>&1; then
    echo "distutils module not found."
    read -p "do you want to install python3-distutils? (y/N):" yn
    case "$yn" in 
        [yY])
            sudo apt-get install python3-distutils
            ;;
        *)
            exit 1;;
    esac
fi

if ! type curl >/dev/null 2>&1; then
    echo "curl not found."
    read -p "do you want to install curl? (y/N):" yn
    case "$yn" in 
        [yY])
            sudo apt-get install curl
            ;;
        *)
            exit 1;;
    esac
fi


if ! type poetry >/dev/null 2>&1; then
    echo "poetry not found."
    read -p "do you want to install poetry? (y/N):" yn
    case "$yn" in 
        [yY])
            curl -sSL https://install.python-poetry.org | python3 -
            ;;
        *)
            exit 1;;
    esac
    export PATH=$HOME/.poetry/bin:$PATH
fi


poetry install
poetry run scripts/installer.py $@
