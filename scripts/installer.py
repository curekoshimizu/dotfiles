#!/usr/bin/env python

import argparse
import pathlib

from dotfiles import Runner
from dotfiles.logics import Gdb, Git, Option, TMux


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="install .XXX files")
    parser.add_argument("-w", dest="overwrite", action="store_true", help="overwrite option")
    parser.add_argument("-d", dest="dest_dir", type=pathlib.Path, default="/tmp/abc", help="destination directory")
    args = parser.parse_args()
    return args


def main() -> None:
    options = parse_args()
    opt = Option(dest_dir=options.dest_dir, overwrite=options.overwrite)
    r = Runner()
    r.add_logic(TMux(opt))
    r.add_logic(Gdb(opt))
    r.add_logic(Git(opt))
    r.run()


if __name__ in "__main__":
    main()
