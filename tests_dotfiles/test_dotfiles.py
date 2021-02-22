import pathlib
import tempfile

from dotfiles import Runner
from dotfiles.logics import Gdb, Git, Option, TMux


def test_tmux() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d))
        r = Runner()
        r.add_logic(TMux(option))
        r.run()
        assert (option.dest_dir / ".tmux.conf").exists()


def test_gdb() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d))
        r = Runner()
        r.add_logic(Gdb(option))
        r.run()
        assert (option.dest_dir / ".gdbinit").exists()


def test_git() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d))
        r = Runner()
        r.add_logic(Git(option))
        r.run()
        assert (option.dest_dir / ".gitconfig").exists()
