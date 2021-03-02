import pathlib
import tempfile

from dotfiles.logics import Gdb, Option, Vim
from dotfiles.runner import Runner


def _check_file_exist(target: pathlib.Path) -> None:
    assert target.exists(), f"{target} not found"
    assert target.stat().st_size > 0


def test_runner() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=False)

        r = Runner()
        r.add_logic(Gdb(option))
        r.add_logic(Vim(option))
        r.run()

        _check_file_exist(option.dest_dir / ".gdbinit")
        _check_file_exist(option.dest_dir / ".vimrc")
        _check_file_exist(option.dest_dir / ".vim")
