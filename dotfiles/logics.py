import abc
import pathlib
import shutil
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


class TMux(Logic):
    def run(self) -> None:
        src = RESOURCES_PATH / ".tmux.conf"
        dst = self._options.dest_dir
        assert src.exists()
        shutil.copy(src, dst)
