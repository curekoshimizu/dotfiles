#!/usr/bin/env python

import argparse
import pathlib

from dotfiles import Runner
from dotfiles.logics import (
    CommandLineHelper,
    Docker,
    Gdb,
    Git,
    Golang,
    NeoVim,
    Node,
    Option,
    Python,
    Rust,
    Terraform,
    TMux,
    Vim,
    Vimperator,
    Zsh,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="install .XXX files", formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--redownload", action="store_true", help="再ダウンロードオプション")
    parser.add_argument(
        "-d", dest="dest_dir", type=pathlib.Path, default=pathlib.Path.home(), help="destination directory"
    )
    return parser.parse_args()


def main() -> None:
    options = parse_args()
    opt = Option(dest_dir=options.dest_dir, redownload=options.redownload)
    r = Runner()

    # add logics
    r.add_logic(TMux(opt))
    r.add_logic(Vimperator(opt))
    r.add_logic(Gdb(opt))
    r.add_logic(Git(opt))
    r.add_logic(Zsh(opt))
    r.add_logic(Vim(opt))
    r.add_logic(NeoVim(opt))
    r.add_logic(CommandLineHelper(opt))
    r.add_logic(Terraform(opt))
    r.add_logic(Docker(opt))
    r.add_logic(Python(opt))
    r.add_logic(Node(opt))
    r.add_logic(Rust(opt))
    r.add_logic(Golang(opt))

    r.run()


if __name__ in "__main__":
    main()
