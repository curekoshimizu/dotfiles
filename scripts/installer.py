#!/usr/bin/env python

import argparse

from dotfiles import Runner


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="install .XXX files")
    parser.add_argument("-w", dest="overwrite", action="store_true", help="overwrite option")
    args = parser.parse_args()
    return args


def main() -> None:
    options = parse_args()
    print(options)
    Runner().run()


if __name__ in "__main__":
    main()
