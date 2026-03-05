from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor

from rich.console import Console

from .logics import ExitCode, Logic, Result

console = Console()


class Runner:
    def __init__(self) -> None:
        self._logics: list[Logic] = []

    def add_logic(self, logic: Logic) -> None:
        self._logics.append(logic)

    def run(self) -> None:
        def _logic_run(logic: Logic) -> Result:
            return logic.run()

        with ThreadPoolExecutor() as executor:
            results: Iterator[Result] = executor.map(_logic_run, self._logics)

        results_list = list(results)
        skipped = []
        for logic, result in zip(self._logics, results_list, strict=True):
            if result.code == ExitCode.SUCCESS:
                if result.warnings:
                    console.print(f"  ⚠️  {logic.name}", style="yellow")
                    for w in result.warnings:
                        console.print(f"      {w}", style="dim yellow")
                else:
                    console.print(f"  ✅ {logic.name}", style="green")
            elif result.code == ExitCode.SKIP:
                console.print(f"  ⏭️  {logic.name}", style="yellow")
                skipped.append(logic.name)
            else:
                assert False, f"Unknown exit code = {result.code}"

        if skipped:
            console.print(
                "\n💡 スキップされた項目があります。"
                "再ダウンロードするには --redownload オプションを付けて実行してください。",
                style="cyan",
            )
