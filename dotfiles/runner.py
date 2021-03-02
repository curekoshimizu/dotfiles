from concurrent.futures import ThreadPoolExecutor
from typing import Iterator, List

import emoji

from .logics import ExitCode, Logic


class Runner:
    def __init__(self) -> None:
        self._logics: List[Logic] = []

    def add_logic(self, logic: Logic) -> None:
        self._logics.append(logic)

    def run(self) -> None:
        def _logic_run(logic: Logic) -> ExitCode:
            return logic.run()

        with ThreadPoolExecutor() as executor:
            results: Iterator[ExitCode] = executor.map(_logic_run, self._logics)

        for logic, exit_code in zip(self._logics, results):
            if exit_code == ExitCode.SUCCESS:
                print(emoji.emojize(f"{logic.name} success:OK_hand:"))
            elif exit_code == ExitCode.SKIP:
                print(f"{logic.name} skipped")
            else:
                assert False, f"Unknown exit code = {exit_code}"
