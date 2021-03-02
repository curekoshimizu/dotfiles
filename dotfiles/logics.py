import abc
import enum
import pathlib
import shutil
import stat
import tempfile
from dataclasses import dataclass

import requests
from git import Repo  # type: ignore

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

# kubectl
if command -v kubectl 1>/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# somehow these settings were overwritten
bindkey "^P" history-beginning-search-backward
bindkey "^N" history-beginning-search-forward
"""

ZSHENV_TEMPLATE = """
ZSHENV_FILE={}
. $ZSHENV_FILE
"""

NEOVIM_TEMPLATE = """
let g:use_neovim = 1
execute 'source {}'
"""


def _warning_message(base: str, program: str) -> None:
    print(f"[warning] {base} needs {program}. But {program} not found")


def program_exist(base: str, program: str) -> bool:
    if shutil.which(program) is not None:
        return True

    _warning_message(base, program)
    return False


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
        program_exist(self.name, "tmux")
        program_exist(self.name, "xsel")
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
        program_exist(self.name, "gdb")
        return SymLink(self._options, ".gdbinit").run()


class Fvwm2(Logic):
    @property
    def name(self) -> str:
        return "fvwm2"

    def run(self) -> ExitCode:
        program_exist(self.name, "fvwm2")
        return SymLink(self._options, ".fvwm2rc").run()


class Git(Logic):
    @property
    def name(self) -> str:
        return "git"

    # TODO: git-lfs check
    def run(self) -> ExitCode:
        program_exist(self.name, "git")
        program_exist(self.name, "git-lfs")
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
        program_exist(self.name, "zsh")
        zsh_completions = self._options.dest_dir / ".zsh-completions"
        if not zsh_completions.exists():
            Repo.clone_from("https://github.com/zsh-users/zsh-completions.git", zsh_completions)

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
        program_exist(self.name, "vim")
        dot_vim = self._options.dest_dir / ".vim" / "autoload"
        if not dot_vim.exists():
            dot_vim.mkdir(parents=True)

        # install plug.vim
        plug_vim = dot_vim / "plug.vim"
        if (not plug_vim.exists()) or self._options.overwrite:
            response = requests.get("https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
            assert response.status_code == 200
            with open(plug_vim, "wb") as f_plug:
                f_plug.write(response.content)

        # install .vimrc
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


class NeoVim(Logic):
    @property
    def name(self) -> str:
        return "nvim"

    def run(self) -> ExitCode:
        program_exist(self.name, "nvim")
        nvim_dir = self._options.dest_dir / ".config" / "nvim"
        if not nvim_dir.exists():
            nvim_dir.mkdir(parents=True)

        # install plug.vim
        plug_dir = self._options.dest_dir / ".local" / "share" / "nvim" / "site" / "autoload"
        if not plug_dir.exists():
            plug_dir.mkdir(parents=True)

        plug_vim = plug_dir / "plug.vim"
        if (not plug_vim.exists()) or self._options.overwrite:
            response = requests.get("https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
            assert response.status_code == 200
            with open(plug_vim, "wb") as f_plug:
                f_plug.write(response.content)

        # install .vimrc
        with tempfile.NamedTemporaryFile(mode="w") as f:
            target = ".vimrc"
            conf_path = RESOURCES_PATH / target
            assert conf_path.exists()
            f.write(NEOVIM_TEMPLATE.format(conf_path).strip())
            f.flush()
            return CopyFile(self._options, src_path=pathlib.Path(f.name), dst_path=nvim_dir / "init.vim").run()


class CommandLineHelper(Logic):
    @property
    def name(self) -> str:
        return "command-line helper"

    def run(self) -> ExitCode:
        program_exist(self.name, "peco")
        program_exist(self.name, "ag")
        program_exist(self.name, "fzf")
        program_exist(self.name, "direnv")

        return ExitCode.SUCCESS


class Docker(Logic):
    @property
    def name(self) -> str:
        return "docker"

    def run(self) -> ExitCode:
        program_exist(self.name, "docker")
        program_exist(self.name, "docker-compose")

        # install docker buildx
        buildx_plugin = self._options.dest_dir / ".docker" / "cli-plugins"
        if not buildx_plugin.exists():
            buildx_plugin.mkdir(parents=True)
        buildx = buildx_plugin / "docker-buildx"
        if (not buildx.exists()) or self._options.overwrite:
            response = requests.get(
                "https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-amd64"
            )
            assert response.status_code == 200
            with open(buildx, "wb") as f_plug:
                f_plug.write(response.content)
            mode = buildx.stat().st_mode
            buildx.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return ExitCode.SUCCESS


class Python(Logic):
    @property
    def name(self) -> str:
        return "python"

    def run(self) -> ExitCode:
        program_exist(self.name, "python3")

        pyenv = self._options.dest_dir / ".pyenv"
        if not pyenv.exists():
            Repo.clone_from("https://github.com/pyenv/pyenv.git", pyenv)

        return ExitCode.SUCCESS


class Node(Logic):
    @property
    def name(self) -> str:
        return "node"

    def run(self) -> ExitCode:
        nvm = self._options.dest_dir / ".nvm"
        if not nvm.exists():
            Repo.clone_from("https://github.com/nvm-sh/nvm.git", nvm)

        return ExitCode.SUCCESS
