import abc
from pathlib import Path

RESOURCES_PATH = Path(__file__).parent / "resources"


class Logic(abc.ABC):
    @abc.abstractmethod
    def run(self) -> None:
        ...


class TMux(Logic):
    def run(self) -> None:
        assert (RESOURCES_PATH / ".tmux.conf").exists()
