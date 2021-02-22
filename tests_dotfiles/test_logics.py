import pathlib
import tempfile

from dotfiles.logics import ExitCode, Fvwm2, Gdb, Git, Option, TMux, Zsh


def test_tmux() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=False)
        r = TMux(option)
        assert r.run() == ExitCode.SUCCESS
        assert (option.dest_dir / ".tmux.conf").exists()
        assert r.run() == ExitCode.SKIP


def test_gdb() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=True)
        r = Gdb(option)
        assert r.run() == ExitCode.SUCCESS
        assert (option.dest_dir / ".gdbinit").exists()
        assert r.run() == ExitCode.SUCCESS


def test_fvwm2() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=True)
        r = Fvwm2(option)
        assert r.run() == ExitCode.SUCCESS
        assert (option.dest_dir / ".fvwm2rc").exists()
        assert r.run() == ExitCode.SUCCESS


def test_git() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=False)
        r = Git(option)
        assert r.run() == ExitCode.SUCCESS
        assert (option.dest_dir / ".gitconfig").exists()
        assert r.run() == ExitCode.SKIP


def test_zsh() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), overwrite=True)
        r = Zsh(option)
        assert r.run() == ExitCode.SUCCESS
        assert (option.dest_dir / ".zshrc").exists()
        assert (option.dest_dir / ".zshenv").exists()
        assert r.run() == ExitCode.SUCCESS
