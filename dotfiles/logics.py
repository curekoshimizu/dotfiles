import abc
import enum
import pathlib
import shutil
import tempfile
from dataclasses import dataclass

RESOURCES_PATH = pathlib.Path(__file__).parent / "resources"


GIT_CONFIG_TEMPLATE = """
[include]
    path = {}
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
"""

ZSHRC_TEMPLATE = """
ZSHRC_FILE={}
. $ZSHRC_FILE
"""

ZSHENV_TEMPLATE = """
ZSHENV_FILE={}
. $ZSHENV_FILE
"""


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

    @property
    @abc.abstractmethod
    def name(self) -> str:
        ...

    @abc.abstractmethod
    def run(self) -> ExitCode:
        ...


class SymLink:
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


class CopyFile:
    def __init__(
        self,
        options: Option,
        src_path: pathlib.Path,
        dst_path: pathlib.Path,
    ) -> None:
        self._options = options
        self._src_path = src_path
        self._dst_path = dst_path

    def run(self) -> ExitCode:
        dst = self._options.dest_dir / self._dst_path
        assert self._src_path.exists(), f"{self._src_path} not found"
        if dst.exists():
            if self._options.overwrite:
                if dst.is_symlink():
                    dst.unlink()
                elif dst.is_file():
                    pass  # try overwrite
                else:
                    return ExitCode.SKIP
            else:
                return ExitCode.SKIP

        shutil.copy(self._src_path, dst)
        return ExitCode.SUCCESS


class TMux(Logic):
    @property
    def name(self) -> str:
        return "tmux"

    def run(self) -> ExitCode:
        return SymLink(self._options, ".tmux.conf").run()


class Vimperator(Logic):
    @property
    def name(self) -> str:
        return "vimperator"

    def run(self) -> ExitCode:
        return SymLink(self._options, ".vimperatorrc").run()


class Gdb(Logic):
    @property
    def name(self) -> str:
        return "gdb"

    def run(self) -> ExitCode:
        return SymLink(self._options, ".gdbinit").run()


class Fvwm2(Logic):
    @property
    def name(self) -> str:
        return "fvwm2"

    def run(self) -> ExitCode:
        return SymLink(self._options, ".fvwm2rc").run()


class Git(Logic):
    @property
    def name(self) -> str:
        return "git"

    # TODO: git-lfs check
    def run(self) -> ExitCode:
        with tempfile.NamedTemporaryFile(mode="w") as f:
            target = ".gitconfig"
            src = RESOURCES_PATH / target
            assert src.exists()
            f.write(GIT_CONFIG_TEMPLATE.format(src).strip())
            f.flush()
            return CopyFile(
                self._options,
                src_path=pathlib.Path(f.name),
                dst_path=self._options.dest_dir / target,
            ).run()


class Zsh(Logic):
    @property
    def name(self) -> str:
        return "zsh"

    def run(self) -> ExitCode:

        with tempfile.NamedTemporaryFile(mode="w") as f:
            conf_path = RESOURCES_PATH / ".zshrc"
            assert conf_path.exists()
            f.write(ZSHRC_TEMPLATE.format(conf_path).strip())
            f.flush()
            ret = CopyFile(
                self._options,
                src_path=pathlib.Path(f.name),
                dst_path=self._options.dest_dir / ".zshrc",
            ).run()
            if ret != ExitCode.SUCCESS:
                return ret

        with tempfile.NamedTemporaryFile(mode="w") as f:
            conf_path = RESOURCES_PATH / ".zshenv"
            assert conf_path.exists()
            f.write(ZSHENV_TEMPLATE.format(conf_path).strip())
            f.flush()
            ret = CopyFile(
                self._options,
                src_path=pathlib.Path(f.name),
                dst_path=self._options.dest_dir / ".zshenv",
            ).run()
            if ret != ExitCode.SUCCESS:
                return ret

        return ret


class Vim(Logic):
    @property
    def name(self) -> str:
        return "vim"

    def run(self) -> ExitCode:

        with tempfile.NamedTemporaryFile(mode="w") as f:
            target = ".vimrc"
            conf_path = RESOURCES_PATH / target
            assert conf_path.exists()
            f.write("execute 'source {}'".format(conf_path))
            f.flush()
            return CopyFile(
                self._options,
                src_path=pathlib.Path(f.name),
                dst_path=self._options.dest_dir / target,
            ).run()
