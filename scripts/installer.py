#!/usr/bin/env python

import argparse
import pathlib

from dotfiles import Runner
from dotfiles.logics import Fvwm2, Gdb, Git, Option, TMux, Vim, Vimperator, Zsh


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="install .XXX files", formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("-w", dest="overwrite", action="store_true", help="overwrite option")
    parser.add_argument(
        "-d", dest="dest_dir", type=pathlib.Path, default=pathlib.Path.home(), help="destination directory"
    )
    args = parser.parse_args()
    return args


def main() -> None:
    options = parse_args()
    opt = Option(dest_dir=options.dest_dir, overwrite=options.overwrite)
    r = Runner()

    # add logics
    r.add_logic(TMux(opt))
    r.add_logic(Vimperator(opt))
    r.add_logic(Gdb(opt))
    r.add_logic(Fvwm2(opt))
    r.add_logic(Git(opt))
    r.add_logic(Zsh(opt))
    r.add_logic(Vim(opt))

    r.run()


if __name__ in "__main__":
    main()
