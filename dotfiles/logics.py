import abc
import enum
import pathlib
from dataclasses import dataclass

RESOURCES_PATH = pathlib.Path(__file__).parent / "resources"


@dataclass
class Option:
    dest_dir: pathlib.Path
    overwrite: bool


class ExitCode(enum.Enum):
    SUCCESS = enum.auto()
    SKIP = enum.auto()


class Logic(abc.ABC):
    def __init__(self, options: Option) -> None:
        self._options = options

    @abc.abstractmethod
    def run(self) -> ExitCode:
        ...


class CopyFile:
    def __init__(self, options: Option, filename: str) -> None:
        self._options = options
        self._filename = filename

    def run(self) -> ExitCode:
        src = RESOURCES_PATH / self._filename
        dst = self._options.dest_dir / self._filename
        assert src.exists(), f"{src} not found"
        if dst.exists():
            if self._options.overwrite:
                if dst.is_symlink():
                    dst.unlink()
            else:
                return ExitCode.SKIP

        dst.symlink_to(src)
        return ExitCode.SUCCESS


class TMux(Logic):
    def run(self) -> ExitCode:
        return CopyFile(self._options, ".tmux.conf").run()


class Gdb(Logic):
    def run(self) -> ExitCode:
        return CopyFile(self._options, ".gdbinit").run()


class Git(Logic):
    # TODO: git-lfs check
    def run(self) -> ExitCode:
        return CopyFile(self._options, ".gitconfig").run()
