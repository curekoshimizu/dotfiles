import abc
import enum
import multiprocessing
import pathlib
import shutil
import stat
import tarfile
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
[fetch]
    parallel = {}
[submodule]
    fetchJobs = {}
[http]
    maxRequests = {}
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


def _warning_message(base: str, program: str, help_message: str = "") -> None:
    print(f"[warning] {base} needs {program}. But {program} not found. {help_message}")


def program_exist(base: str, program: str, help_message: str = "") -> bool:
    if shutil.which(program) is not None:
        return True

    _warning_message(base, program, help_message)
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
    def __init__(self, overwrite: bool, dest_dir: pathlib.Path, filename: str) -> None:
        self._overwrite = overwrite
        self._dest_dir = dest_dir
        self._filename = filename

    def run(self) -> ExitCode:
        src = RESOURCES_PATH / self._filename
        dst = self._dest_dir / self._filename
        assert src.exists(), f"{src} not found"
        if dst.exists():
            if self._overwrite:
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
        return SymLink(self._options.overwrite, self._options.dest_dir, ".tmux.conf").run()


class Vimperator(Logic):
    @property
    def name(self) -> str:
        return "vimperator"

    def run(self) -> ExitCode:
        return SymLink(self._options.overwrite, self._options.dest_dir, ".vimperatorrc").run()


class Gdb(Logic):
    @property
    def name(self) -> str:
        return "gdb"

    def run(self) -> ExitCode:
        program_exist(self.name, "gdb")
        return SymLink(self._options.overwrite, self._options.dest_dir, ".gdbinit").run()


class Fvwm2(Logic):
    @property
    def name(self) -> str:
        return "fvwm2"

    def run(self) -> ExitCode:
        program_exist(self.name, "fvwm2")
        return SymLink(self._options.overwrite, self._options.dest_dir, ".fvwm2rc").run()


class Git(Logic):
    @property
    def name(self) -> str:
        return "git"

    # TODO: git-lfs check
    def run(self) -> ExitCode:
        program_exist(self.name, "git")
        program_exist(self.name, "git-lfs")
        # .config/git/ignore
        config_git = self._options.dest_dir / ".config" / "git"
        if not config_git.exists():
            config_git.mkdir(parents=True)
        ret = SymLink(self._options.overwrite, config_git, "ignore").run()
        if ret != ExitCode.SUCCESS:
            return ret
        # .gitconfig
        with tempfile.NamedTemporaryFile(mode="w") as f:
            target = ".gitconfig"
            src = RESOURCES_PATH / target
            assert src.exists()
            nthreads = multiprocessing.cpu_count()
            f.write(GIT_CONFIG_TEMPLATE.format(src, nthreads, nthreads, nthreads).lstrip())
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
            f.write(ZSHRC_TEMPLATE.format(conf_path).lstrip())
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
            f.write(ZSHENV_TEMPLATE.format(conf_path).lstrip())
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
            f.write(NEOVIM_TEMPLATE.format(conf_path).lstrip())
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

        # install docker-compose
        response = requests.get("https://api.github.com/repos/docker/compose/releases/latest")
        content = response.json()
        assert "name" in content
        compose_release_name = content["name"]

        bin_dir = self._options.dest_dir / "bin"
        if not bin_dir.exists():
            bin_dir.mkdir(parents=True)
        compose = bin_dir / "docker-compose"

        if (not compose.exists()) or self._options.overwrite:
            response = requests.get(
                f"https://github.com/docker/compose/releases/download/{compose_release_name}/docker-compose-Linux-x86_64"
            )
            assert response.status_code == 200
            with open(compose, "wb") as f_plug:
                f_plug.write(response.content)
            mode = compose.stat().st_mode
            compose.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

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
        return "nodejs"

    def run(self) -> ExitCode:
        program_exist(self.name, "npm", "try 'nvm install --lts --latest-npm'.")
        program_exist(self.name, "node", "try 'nvm install --lst --latest-npm'.")

        nvm = self._options.dest_dir / ".nvm"
        if nvm.exists():
            return ExitCode.SKIP
        else:
            Repo.clone_from("https://github.com/nvm-sh/nvm.git", nvm)
            return ExitCode.SUCCESS


class Rust(Logic):
    @property
    def name(self) -> str:
        return "rust"

    def run(self) -> ExitCode:
        program_exist(self.name, "rustc", "try \"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\".")

        # install rust-analyzer
        bin_dir = self._options.dest_dir / "bin"
        if not bin_dir.exists():
            bin_dir.mkdir(parents=True)
        rust_analyzer = bin_dir / "rust-analyzer"

        if (not rust_analyzer.exists()) or self._options.overwrite:
            response = requests.get(
                "https://github.com/rust-analyzer/rust-analyzer/releases/download/2021-05-17/rust-analyzer-linux"
            )
            assert response.status_code == 200
            with open(rust_analyzer, "wb") as f_plug:
                f_plug.write(response.content)
            mode = rust_analyzer.stat().st_mode
            rust_analyzer.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return ExitCode.SUCCESS


class Golang(Logic):
    @property
    def name(self) -> str:
        return "golang"

    def run(self) -> ExitCode:
        # install golang

        target = self._options.dest_dir / ".golang"
        if target.exists() and (not self._options.overwrite):
            return ExitCode.SKIP
        else:
            if target.exists():
                assert (target / "bin" / "go").exists()
                shutil.rmtree(target)

            with tempfile.TemporaryDirectory(dir=self._options.dest_dir) as d:
                temp_dir = pathlib.Path(d)
                response = requests.get("https://golang.org/VERSION?m=text")
                assert response.status_code == 200
                filename = f"{response.text}.linux-amd64.tar.gz"
                response = requests.get(f"https://golang.org/dl/{filename}")

                targz = temp_dir / filename

                with open(targz, "wb") as f:
                    f.write(response.content)

                with tarfile.open(targz, "r:gz") as t:
                    t.extractall(path=d)
                assert (temp_dir / "go").exists()
                (temp_dir / "go").rename(target)
            return ExitCode.SUCCESS
