#!/usr/bin/env bash

set -eu

if ! type python3 >/dev/null 2>&1; then
    echo "python3 not found."
    exit 1
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

if ! type uv >/dev/null 2>&1; then
    echo "uv not found."
    read -p "do you want to install uv? (y/N):" yn
    case "$yn" in
        [yY])
            curl -LsSf https://astral.sh/uv/install.sh | sh
            export PATH=$HOME/.local/bin:$PATH
            ;;
        *)
            exit 1;;
    esac
fi

uv sync
uv run scripts/installer.py $@
