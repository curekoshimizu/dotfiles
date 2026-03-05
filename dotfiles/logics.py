import abc
import enum
import multiprocessing
import pathlib
import platform
import re
import shutil
import stat
import sys
import tarfile
import tempfile
from dataclasses import dataclass

import requests
from git import Repo

RESOURCES_PATH = pathlib.Path(__file__).parent / "resources"

HTTP_OK = 200
REQUEST_TIMEOUT = 30


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
"""

ZSHENV_TEMPLATE = """
ZSHENV_FILE={}
. $ZSHENV_FILE
"""

NEOVIM_TEMPLATE = """
let g:use_neovim = 1
execute 'source {}'
"""


def _warning_message(base: str, program: str, help_message: str = "") -> str:
    return f"[warning] {base} needs {program}. But {program} not found. {help_message}"


def program_exist(base: str, program: str, help_message: str = "", *, warnings: list[str] | None = None) -> bool:
    if shutil.which(program) is not None:
        return True

    msg = _warning_message(base, program, help_message)
    if warnings is not None:
        warnings.append(msg)
    return False


def _get_platform_info() -> tuple[str, str]:
    """OS名とアーキテクチャを返す - linux/amd64, darwin/arm64 など."""
    os_name = platform.system().lower()
    machine = platform.machine().lower()
    arch_map = {"x86_64": "amd64", "aarch64": "arm64"}
    return os_name, arch_map.get(machine, machine)


def _get_github_latest_release_url(repo: str, asset_pattern: str) -> str:
    """GitHubリポジトリの最新リリースから指定パターンに一致するアセットURLを返す."""
    response = requests.get(f"https://api.github.com/repos/{repo}/releases/latest", timeout=REQUEST_TIMEOUT)
    assert response.status_code == HTTP_OK
    data = response.json()
    for asset in data["assets"]:
        if re.search(asset_pattern, asset["name"]):
            url: str = asset["browser_download_url"]
            return url
    msg = f"{repo} の最新リリースにパターン '{asset_pattern}' に一致するアセットが見つかりません。"
    raise ValueError(msg)


@dataclass
class Option:
    dest_dir: pathlib.Path
    redownload: bool


class ExitCode(enum.Enum):
    SUCCESS = enum.auto()
    SKIP = enum.auto()


@dataclass
class Result:
    code: ExitCode
    warnings: list[str]


class Logic(abc.ABC):
    def __init__(self, options: Option) -> None:
        self._options = options

    @property
    @abc.abstractmethod
    def name(self) -> str: ...

    @abc.abstractmethod
    def run(self) -> Result: ...


class SymLink:
    def __init__(self, *, dest_dir: pathlib.Path, filename: str, dest_filename: str | None = None) -> None:
        self._dest_dir = dest_dir
        self._filename = filename
        self._dest_filename: str = filename if dest_filename is None else dest_filename

    def run(self) -> ExitCode:
        src = RESOURCES_PATH / self._filename
        dst = self._dest_dir / self._dest_filename
        assert src.exists(), f"{src} not found"

        if dst.exists() or dst.is_symlink():
            dst.unlink()

        dst.symlink_to(src)
        return ExitCode.SUCCESS


MARKER_BEGIN = "=== BEGIN DOTFILES MANAGED BLOCK ==="
MARKER_END = "=== END DOTFILES MANAGED BLOCK ==="


class MarkerNotFoundError(Exception):
    """既存ファイルにマーカーが見つからない場合のエラー."""


class ManagedBlockWriter:
    def __init__(
        self,
        *,
        options: Option,
        content: str,
        dst_path: pathlib.Path,
        comment_prefix: str = "#",
    ) -> None:
        self._options = options
        self._content = content
        self._dst_path = dst_path
        self._comment_prefix = comment_prefix

    def run(self) -> ExitCode:
        dst = self._options.dest_dir / self._dst_path
        begin_marker = f"{self._comment_prefix} {MARKER_BEGIN}"
        end_marker = f"{self._comment_prefix} {MARKER_END}"
        managed_block = f"{begin_marker}\n{self._content}\n{end_marker}\n"

        if not dst.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(managed_block)
            return ExitCode.SUCCESS

        existing = dst.read_text()
        if begin_marker in existing and end_marker in existing:
            begin_idx = existing.index(begin_marker)
            end_marker_idx = existing.index(end_marker)
            if begin_idx > end_marker_idx:
                msg = f"{dst} のマーカーが逆順です。BEGINがENDより前にある必要があります。"
                raise MarkerNotFoundError(msg)
            end_idx = end_marker_idx + len(end_marker)
            after = existing[end_idx:]
            after = after.removeprefix("\n")
            dst.write_text(existing[:begin_idx] + managed_block + after)
            return ExitCode.SUCCESS

        msg = f"{dst} にマーカーが見つかりません。ファイルを削除して再実行するか、手動でマーカーを追加してください。"
        raise MarkerNotFoundError(msg)


class TMux(Logic):
    @property
    def name(self) -> str:
        return "tmux"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "tmux", warnings=warnings)

        conf_path = RESOURCES_PATH / ".tmux.conf.common"
        keybindings_path = RESOURCES_PATH / ".tmux.conf.keybindings"
        conf2_path = RESOURCES_PATH / ".tmux.conf.platform"
        assert conf_path.exists()
        assert keybindings_path.exists()
        assert conf2_path.exists()
        content = f"source-file '{conf_path}'\nsource-file '{keybindings_path}'\nsource-file '{conf2_path}'"
        code = ManagedBlockWriter(options=self._options, content=content, dst_path=pathlib.Path(".tmux.conf")).run()
        return Result(code=code, warnings=warnings)


class Vimperator(Logic):
    @property
    def name(self) -> str:
        return "vimperator"

    def run(self) -> Result:
        code = SymLink(dest_dir=self._options.dest_dir, filename=".vimperatorrc").run()
        return Result(code=code, warnings=[])


class Gdb(Logic):
    @property
    def name(self) -> str:
        return "gdb"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "gdb", warnings=warnings)
        code = SymLink(dest_dir=self._options.dest_dir, filename=".gdbinit").run()
        return Result(code=code, warnings=warnings)


class Fvwm2(Logic):
    @property
    def name(self) -> str:
        return "fvwm2"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "fvwm2", warnings=warnings)
        code = SymLink(dest_dir=self._options.dest_dir, filename=".fvwm2rc").run()
        return Result(code=code, warnings=warnings)


class Git(Logic):
    @property
    def name(self) -> str:
        return "git"

    # TODO: git-lfs check
    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "git", warnings=warnings)
        program_exist(self.name, "git-lfs", warnings=warnings)
        # .config/git/ignore
        config_git = self._options.dest_dir / ".config" / "git"
        if not config_git.exists():
            config_git.mkdir(parents=True)
        ret = SymLink(dest_dir=config_git, filename="ignore").run()
        if ret != ExitCode.SUCCESS:
            return Result(code=ret, warnings=warnings)
        # .gitconfig
        target = ".gitconfig"
        src = RESOURCES_PATH / target
        assert src.exists()
        nthreads = multiprocessing.cpu_count()
        content = GIT_CONFIG_TEMPLATE.format(src, nthreads, nthreads, nthreads).strip()
        code = ManagedBlockWriter(options=self._options, content=content, dst_path=pathlib.Path(target)).run()
        return Result(code=code, warnings=warnings)


class Zsh(Logic):
    @property
    def name(self) -> str:
        return "zsh"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "zsh", warnings=warnings)
        zsh_completions = self._options.dest_dir / ".zsh-completions"
        if not zsh_completions.exists():
            Repo.clone_from("https://github.com/zsh-users/zsh-completions.git", zsh_completions)

        conf_path = RESOURCES_PATH / ".zshrc"
        assert conf_path.exists()
        ret = ManagedBlockWriter(
            options=self._options, content=ZSHRC_TEMPLATE.format(conf_path).strip(), dst_path=pathlib.Path(".zshrc")
        ).run()
        if ret != ExitCode.SUCCESS:
            return Result(code=ret, warnings=warnings)

        conf_path = RESOURCES_PATH / ".zshenv"
        assert conf_path.exists()
        code = ManagedBlockWriter(
            options=self._options, content=ZSHENV_TEMPLATE.format(conf_path).strip(), dst_path=pathlib.Path(".zshenv")
        ).run()
        return Result(code=code, warnings=warnings)


class Vim(Logic):
    @property
    def name(self) -> str:
        return "vim"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "vim", warnings=warnings)
        dot_vim = self._options.dest_dir / ".vim" / "autoload"
        if not dot_vim.exists():
            dot_vim.mkdir(parents=True)

        # install plug.vim
        plug_vim = dot_vim / "plug.vim"
        if (not plug_vim.exists()) or self._options.redownload:
            response = requests.get(
                "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim", timeout=REQUEST_TIMEOUT
            )
            assert response.status_code == HTTP_OK
            with plug_vim.open("wb") as f_plug:
                f_plug.write(response.content)

        # install .vimrc
        conf_path = RESOURCES_PATH / ".vimrc"
        assert conf_path.exists()
        code = ManagedBlockWriter(
            options=self._options,
            content=f"execute 'source {conf_path}'",
            dst_path=pathlib.Path(".vimrc"),
            comment_prefix='"',
        ).run()
        return Result(code=code, warnings=warnings)


class NeoVim(Logic):
    @property
    def name(self) -> str:
        return "nvim"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "nvim", warnings=warnings)
        nvim_dir = self._options.dest_dir / ".config" / "nvim"
        if not nvim_dir.exists():
            nvim_dir.mkdir(parents=True)

        # install plug.vim
        plug_dir = self._options.dest_dir / ".local" / "share" / "nvim" / "site" / "autoload"
        if not plug_dir.exists():
            plug_dir.mkdir(parents=True)

        plug_vim = plug_dir / "plug.vim"
        if (not plug_vim.exists()) or self._options.redownload:
            response = requests.get(
                "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim", timeout=REQUEST_TIMEOUT
            )
            assert response.status_code == HTTP_OK
            with plug_vim.open("wb") as f_plug:
                f_plug.write(response.content)

        # install init.vim
        conf_path = RESOURCES_PATH / ".vimrc"
        assert conf_path.exists()
        code = ManagedBlockWriter(
            options=self._options,
            content=NEOVIM_TEMPLATE.format(conf_path).strip(),
            dst_path=pathlib.Path(".config") / "nvim" / "init.vim",
            comment_prefix='"',
        ).run()
        return Result(code=code, warnings=warnings)


class CommandLineHelper(Logic):
    @property
    def name(self) -> str:
        return "command-line helper"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "peco", warnings=warnings)
        program_exist(self.name, "ag", warnings=warnings)
        program_exist(self.name, "fzf", warnings=warnings)
        program_exist(self.name, "direnv", warnings=warnings)

        return Result(code=ExitCode.SUCCESS, warnings=warnings)


class Terraform(Logic):
    @property
    def name(self) -> str:
        return "terraform"

    def run(self) -> Result:
        tfenv = self._options.dest_dir / ".tfenv"
        if not tfenv.exists():
            Repo.clone_from("https://github.com/tfutils/tfenv.git", tfenv)

        return Result(code=ExitCode.SUCCESS, warnings=[])


class Docker(Logic):
    @property
    def name(self) -> str:
        return "docker"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "docker", warnings=warnings)
        os_name, arch = _get_platform_info()

        # install docker buildx (Macでは Docker Desktop に同梱のためスキップ)
        if os_name != "darwin":
            buildx_plugin = self._options.dest_dir / ".docker" / "cli-plugins"
            if not buildx_plugin.exists():
                buildx_plugin.mkdir(parents=True)
            buildx = buildx_plugin / "docker-buildx"
            if (not buildx.exists()) or self._options.redownload:
                url = _get_github_latest_release_url("docker/buildx", rf"buildx-v[\d.]+\.{os_name}-{arch}$")
                response = requests.get(url, timeout=REQUEST_TIMEOUT)
                assert response.status_code == HTTP_OK
                with buildx.open("wb") as f_plug:
                    f_plug.write(response.content)
                mode = buildx.stat().st_mode
                buildx.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        # install docker-compose
        bin_dir = self._options.dest_dir / "bin"
        if not bin_dir.exists():
            bin_dir.mkdir(parents=True)
        compose = bin_dir / "docker-compose"

        if (not compose.exists()) or self._options.redownload:
            arch_compose_map = {"amd64": "x86_64", "arm64": "aarch64"}
            arch_compose = arch_compose_map.get(arch, arch)
            url = _get_github_latest_release_url("docker/compose", rf"docker-compose-{os_name}-{arch_compose}$")
            response = requests.get(url, timeout=REQUEST_TIMEOUT)
            assert response.status_code == HTTP_OK
            with compose.open("wb") as f_plug:
                f_plug.write(response.content)
            mode = compose.stat().st_mode
            compose.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return Result(code=ExitCode.SUCCESS, warnings=warnings)


class Python(Logic):
    @property
    def name(self) -> str:
        return "python"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "python3", warnings=warnings)
        if not program_exist(self.name, "uv", warnings=warnings):
            warnings.append("uv not found. Install it from https://docs.astral.sh/uv/getting-started/installation/")

        pyenv = self._options.dest_dir / ".pyenv"
        if not pyenv.exists():
            Repo.clone_from("https://github.com/pyenv/pyenv.git", pyenv)

        return Result(code=ExitCode.SUCCESS, warnings=warnings)


class Node(Logic):
    @property
    def name(self) -> str:
        return "nodejs"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(self.name, "npm", "try 'nvm install --lts --latest-npm'.", warnings=warnings)
        program_exist(self.name, "node", "try 'nvm install --lts --latest-npm'.", warnings=warnings)

        nvm = self._options.dest_dir / ".nvm"
        if nvm.exists():
            return Result(code=ExitCode.SKIP, warnings=warnings)
        Repo.clone_from("https://github.com/nvm-sh/nvm.git", nvm)
        return Result(code=ExitCode.SUCCESS, warnings=warnings)


class Rust(Logic):
    @property
    def name(self) -> str:
        return "rust"

    def run(self) -> Result:
        warnings: list[str] = []
        program_exist(
            self.name,
            "rustc",
            "try \"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\".",
            warnings=warnings,
        )
        program_exist(self.name, "rust-analyzer", "try 'rustup component add rust-analyzer'.", warnings=warnings)
        return Result(code=ExitCode.SUCCESS, warnings=warnings)


class Golang(Logic):
    @property
    def name(self) -> str:
        return "golang"

    def run(self) -> Result:
        # install golang

        target = self._options.dest_dir / ".golang"
        if target.exists() and (not self._options.redownload):
            return Result(code=ExitCode.SKIP, warnings=[])
        if target.exists():
            assert (target / "bin" / "go").exists()
            shutil.rmtree(target)

        with tempfile.TemporaryDirectory(dir=self._options.dest_dir) as d:
            temp_dir = pathlib.Path(d)
            response = requests.get("https://golang.org/VERSION?m=text", timeout=REQUEST_TIMEOUT)
            assert response.status_code == HTTP_OK
            goversion = response.text.split("\n")[0]
            os_name, arch = _get_platform_info()
            filename = f"{goversion}.{os_name}-{arch}.tar.gz"
            response = requests.get(f"https://golang.org/dl/{filename}", timeout=REQUEST_TIMEOUT)

            targz = temp_dir / filename

            with targz.open("wb") as f:
                f.write(response.content)

            with tarfile.open(targz, "r:gz") as t:
                t.extractall(path=d, filter="data")
            assert (temp_dir / "go").exists()
            (temp_dir / "go").rename(target)
        return Result(code=ExitCode.SUCCESS, warnings=[])
