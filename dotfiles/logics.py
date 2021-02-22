import abc
import pathlib
from dataclasses import dataclass

RESOURCES_PATH = pathlib.Path(__file__).parent / "resources"


@dataclass
class Option:
    dest_dir: pathlib.Path


class Logic(abc.ABC):
    def __init__(self, options: Option) -> None:
        self._options = options

    @abc.abstractmethod
    def run(self) -> None:
        ...


class CopyFile:
    def __init__(self, options: Option, filename: str) -> None:
        self._options = options
        self._filename = filename

    def run(self) -> None:
        src = RESOURCES_PATH / self._filename
        dst = self._options.dest_dir / self._filename
        assert src.exists()
        assert not dst.exists()
        dst.symlink_to(src)


class TMux(Logic):
    def run(self) -> None:
        CopyFile(self._options, ".tmux.conf").run()


class Gdb(Logic):
    def run(self) -> None:
        CopyFile(self._options, ".gdbinit").run()


class Git(Logic):
    # TODO: git-lfs check
    def run(self) -> None:
        CopyFile(self._options, ".gitconfig").run()
