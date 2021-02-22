import abc
from pathlib import Path
from typing import List

RESOURCES_PATH = Path(__file__).parent.parent / "resources"


class Logic(abc.ABC):
    @abc.abstractmethod
    def run(self) -> None:
        ...


class Runner:
    def __init__(self) -> None:
        self._logics: List[Logic] = []

    def add_logic(self, logic: Logic) -> None:
        self._logics.append(logic)

    def run(self) -> None:
        for logic in self._logics:
            logic.run()


class TMux(Logic):
    def run(self) -> None:
        assert (RESOURCES_PATH / ".tmux.conf").exists()
