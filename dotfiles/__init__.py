from typing import List

from .logics import ExitCode, Logic


class Runner:
    def __init__(self) -> None:
        self._logics: List[Logic] = []

    def add_logic(self, logic: Logic) -> None:
        self._logics.append(logic)

    def run(self) -> None:
        for logic in self._logics:
            exit_code = logic.run()
            if exit_code == ExitCode.SKIP:
                print(f"{logic.name} skipped")
