#!/usr/bin/env bash

set -eu

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
            curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
            ;;
        *)
            exit 1;;
    esac
    export PATH=$HOME/.poetry/bin:$PATH
fi


poetry install
poetry run scripts/installer.py $@
