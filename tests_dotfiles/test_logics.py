import pathlib
import sys
import tempfile

import pytest

from dotfiles.logics import (
    RESOURCES_PATH,
    CommandLineHelper,
    Docker,
    ExitCode,
    Fvwm2,
    Gdb,
    Git,
    Golang,
    ManagedBlockWriter,
    MarkerNotFoundError,
    NeoVim,
    Node,
    Option,
    Python,
    Rust,
    SymLink,
    Terraform,
    TMux,
    Vim,
    Vimperator,
    Zsh,
    program_exist,
)


def _check_file_exist(target: pathlib.Path) -> None:
    assert target.exists(), f"{target} not found"
    assert target.stat().st_size > 0


def _check_has_markers(target: pathlib.Path, comment_prefix: str = "#") -> None:
    content = target.read_text()
    assert f"{comment_prefix} === BEGIN DOTFILES MANAGED BLOCK ===" in content
    assert f"{comment_prefix} === END DOTFILES MANAGED BLOCK ===" in content


# --- ManagedBlockWriter 単体テスト ---


# 新規ファイルにマーカー付きで書き込まれること
def test_managed_block_writer_new_file() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        ret = ManagedBlockWriter(options=option, content="hello", dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS
        dst = pathlib.Path(d) / "test.conf"
        content = dst.read_text()
        assert "# === BEGIN DOTFILES MANAGED BLOCK ===" in content
        assert "hello" in content
        assert "# === END DOTFILES MANAGED BLOCK ===" in content


# マーカー範囲のみ置換され、外側のユーザー設定が保持されること
def test_managed_block_writer_update_preserves_outside() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"

        # 初回書き込み
        ManagedBlockWriter(options=option, content="v1", dst_path=pathlib.Path("test.conf")).run()

        # ユーザーがマーカー外に手動で追記
        dst.write_text("# user before\n" + dst.read_text() + "# user after\n")

        # 更新
        ret = ManagedBlockWriter(options=option, content="v2", dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS

        content = dst.read_text()
        assert "# user before" in content
        assert "# user after" in content
        assert "v2" in content
        assert "v1" not in content


# マーカーなしの既存ファイルに対してはMarkerNotFoundErrorが発生すること
def test_managed_block_writer_no_markers_raises() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"
        dst.write_text("some existing content without markers\n")

        with pytest.raises(MarkerNotFoundError):
            ManagedBlockWriter(options=option, content="new", dst_path=pathlib.Path("test.conf")).run()


# 親ディレクトリが存在しなくても自動作成されること
def test_managed_block_writer_creates_parent_dirs() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        ret = ManagedBlockWriter(options=option, content="hello", dst_path=pathlib.Path("sub/dir/test.conf")).run()
        assert ret == ExitCode.SUCCESS
        _check_file_exist(pathlib.Path(d) / "sub" / "dir" / "test.conf")


# Vim形式のコメントプレフィックス (") でマーカーが使われること
def test_managed_block_writer_vim_comment_prefix() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        ManagedBlockWriter(
            options=option, content="set nocompatible", dst_path=pathlib.Path(".vimrc"), comment_prefix='"'
        ).run()
        dst = pathlib.Path(d) / ".vimrc"
        content = dst.read_text()
        assert '" === BEGIN DOTFILES MANAGED BLOCK ===' in content
        assert '" === END DOTFILES MANAGED BLOCK ===' in content


# BEGINマーカーだけでENDがない場合もMarkerNotFoundErrorになること
def test_managed_block_writer_only_begin_marker_raises() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"
        dst.write_text("# === BEGIN DOTFILES MANAGED BLOCK ===\nold content\n")

        with pytest.raises(MarkerNotFoundError):
            ManagedBlockWriter(options=option, content="new", dst_path=pathlib.Path("test.conf")).run()


# ENDマーカーだけでBEGINがない場合もMarkerNotFoundErrorになること
def test_managed_block_writer_only_end_marker_raises() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"
        dst.write_text("old content\n# === END DOTFILES MANAGED BLOCK ===\n")

        with pytest.raises(MarkerNotFoundError):
            ManagedBlockWriter(options=option, content="new", dst_path=pathlib.Path("test.conf")).run()


# 3回以上の連続更新でもマーカー外のユーザー設定が保持されること
def test_managed_block_writer_multiple_updates() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"
        path = pathlib.Path("test.conf")

        # 初回書き込み
        ManagedBlockWriter(options=option, content="v1", dst_path=path).run()

        # ユーザーがマーカー外に手動で追記
        dst.write_text("# header\n" + dst.read_text() + "# footer\n")

        # 2回目更新
        ManagedBlockWriter(options=option, content="v2", dst_path=path).run()

        # 3回目更新
        ManagedBlockWriter(options=option, content="v3", dst_path=path).run()

        content = dst.read_text()
        assert "# header" in content
        assert "# footer" in content
        assert "v3" in content
        assert "v1" not in content
        assert "v2" not in content


# 空のcontentでも正常にマーカーブロックが書き込まれること
def test_managed_block_writer_empty_content() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        ret = ManagedBlockWriter(options=option, content="", dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS
        dst = pathlib.Path(d) / "test.conf"
        _check_has_markers(dst)


# 複数行のcontentが正しくマーカー内に収まること
def test_managed_block_writer_multiline_content() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        content = "line1\nline2\nline3"
        ret = ManagedBlockWriter(options=option, content=content, dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS

        file_content = (pathlib.Path(d) / "test.conf").read_text()
        lines = file_content.splitlines()

        # BEGINとENDの間に全行が含まれていること
        assert lines[0] == "# === BEGIN DOTFILES MANAGED BLOCK ==="
        assert lines[1] == "line1"
        assert lines[2] == "line2"
        assert lines[3] == "line3"
        assert lines[4] == "# === END DOTFILES MANAGED BLOCK ==="


# ENDマーカーがBEGINより前にある場合はエラーになること
def test_managed_block_writer_end_before_begin_raises() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"
        # ENDを先、BEGINを後に書く
        dst.write_text(
            "# === END DOTFILES MANAGED BLOCK ===\nmiddle\n# === BEGIN DOTFILES MANAGED BLOCK ===\ncontent\n"
        )

        with pytest.raises(MarkerNotFoundError):
            ManagedBlockWriter(options=option, content="new", dst_path=pathlib.Path("test.conf")).run()


# contentにマーカー文字列が含まれていても初回書き込みが正常に動作すること
def test_managed_block_writer_content_with_marker_string() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        # contentにBEGINマーカー文字列を含める
        content = "normal line\n# === BEGIN DOTFILES MANAGED BLOCK ===\ntricky"
        ret = ManagedBlockWriter(options=option, content=content, dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS
        file_content = (pathlib.Path(d) / "test.conf").read_text()
        # マーカーが正しく書き込まれていること
        _check_has_markers(pathlib.Path(d) / "test.conf")
        assert "normal line" in file_content
        assert "tricky" in file_content


# 同一contentで2回実行してもファイル内容が変わらないこと - 冪等性の確認
def test_managed_block_writer_idempotent() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        path = pathlib.Path("test.conf")
        dst = pathlib.Path(d) / "test.conf"

        ManagedBlockWriter(options=option, content="same content", dst_path=path).run()

        # ユーザーがマーカー外に手動で追記
        dst.write_text("# user config\n" + dst.read_text())

        # 1回目の更新
        ManagedBlockWriter(options=option, content="same content", dst_path=path).run()
        content_after_first = dst.read_text()

        # 2回目の更新 - 同一content
        ManagedBlockWriter(options=option, content="same content", dst_path=path).run()
        content_after_second = dst.read_text()

        assert content_after_first == content_after_second
        assert "# user config" in content_after_second


# マーカーペアが複数存在する場合、最初のペアが使われること
def test_managed_block_writer_multiple_marker_pairs() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        dst = pathlib.Path(d) / "test.conf"

        # 初回書き込み
        ManagedBlockWriter(options=option, content="v1", dst_path=pathlib.Path("test.conf")).run()

        # ユーザーが手動でもう1組のマーカーを追記 - 実際にはありえないが防御テスト
        original = dst.read_text()
        dst.write_text(
            original
            + "# === BEGIN DOTFILES MANAGED BLOCK ===\n"
            + "manual block\n"
            + "# === END DOTFILES MANAGED BLOCK ===\n"
        )

        # 更新 → 最初のマーカーペアが置換されること
        ret = ManagedBlockWriter(options=option, content="v2", dst_path=pathlib.Path("test.conf")).run()
        assert ret == ExitCode.SUCCESS
        content = dst.read_text()
        assert "v2" in content
        # 手動追加した2つ目のブロックは残っている
        assert "manual block" in content


# --- SymLink 単体テスト ---


# シンボリックリンクが新規作成されること
def test_symlink_new() -> None:
    with tempfile.TemporaryDirectory() as d:
        ret = SymLink(dest_dir=pathlib.Path(d), filename=".gdbinit").run()
        assert ret == ExitCode.SUCCESS
        dst = pathlib.Path(d) / ".gdbinit"
        assert dst.is_symlink()


# 再実行しても常にSUCCESSで再作成されること
def test_symlink_rerun() -> None:
    with tempfile.TemporaryDirectory() as d:
        dest_dir = pathlib.Path(d)
        SymLink(dest_dir=dest_dir, filename=".gdbinit").run()

        ret = SymLink(dest_dir=dest_dir, filename=".gdbinit").run()
        assert ret == ExitCode.SUCCESS
        assert (dest_dir / ".gdbinit").is_symlink()


# dest_filenameを指定すると別名でリンクが作られること
def test_symlink_dest_filename() -> None:
    with tempfile.TemporaryDirectory() as d:
        ret = SymLink(dest_dir=pathlib.Path(d), filename=".gdbinit", dest_filename="my_gdbinit").run()
        assert ret == ExitCode.SUCCESS
        assert (pathlib.Path(d) / "my_gdbinit").is_symlink()
        assert not (pathlib.Path(d) / ".gdbinit").exists()


# リンク先がRESOURCES_PATH内の正しいファイルを指していること
def test_symlink_points_to_correct_target() -> None:
    with tempfile.TemporaryDirectory() as d:
        SymLink(dest_dir=pathlib.Path(d), filename=".gdbinit").run()
        dst = pathlib.Path(d) / ".gdbinit"
        expected_target = RESOURCES_PATH / ".gdbinit"
        actual_target = dst.readlink()
        assert actual_target == expected_target


# 通常ファイルが存在しても削除して再作成されること
def test_symlink_replace_regular_file() -> None:
    with tempfile.TemporaryDirectory() as d:
        dest_dir = pathlib.Path(d)
        dst = dest_dir / ".gdbinit"
        dst.write_text("regular file content\n")
        assert dst.exists()
        assert not dst.is_symlink()

        ret = SymLink(dest_dir=dest_dir, filename=".gdbinit").run()
        assert ret == ExitCode.SUCCESS
        assert dst.is_symlink()


# dangling symlink も削除して再作成されること
def test_symlink_replace_dangling() -> None:
    with tempfile.TemporaryDirectory() as d:
        dest_dir = pathlib.Path(d)
        dst = dest_dir / ".gdbinit"
        dst.symlink_to("/nonexistent/path")
        assert dst.is_symlink()
        assert not dst.exists()  # dangling

        ret = SymLink(dest_dir=dest_dir, filename=".gdbinit").run()
        assert ret == ExitCode.SUCCESS
        assert dst.is_symlink()
        assert dst.exists()  # もう壊れていない


# --- program_exist 単体テスト ---


# 存在するプログラムに対してTrueを返すこと
def test_program_exist_found() -> None:
    # python3 はテスト実行環境に必ず存在する
    warnings: list[str] = []
    assert program_exist("test", "python3", warnings=warnings) is True
    assert warnings == []


# 存在しないプログラムに対してFalseを返しwarningsに追加されること
def test_program_exist_not_found() -> None:
    warnings: list[str] = []
    assert program_exist("test", "nonexistent_program_xyz", warnings=warnings) is False
    assert len(warnings) == 1
    assert "nonexistent_program_xyz" in warnings[0]
    assert "[warning]" in warnings[0]


# --- Logic テスト ---


# 各Logicのnameプロパティが期待通りの文字列を返すこと
def test_logic_names() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        assert TMux(option).name == "tmux"
        assert Vimperator(option).name == "vimperator"
        assert Gdb(option).name == "gdb"
        assert Fvwm2(option).name == "fvwm2"
        assert Git(option).name == "git"
        assert Zsh(option).name == "zsh"
        assert Vim(option).name == "vim"
        assert NeoVim(option).name == "nvim"
        assert CommandLineHelper(option).name == "command-line helper"
        assert Terraform(option).name == "terraform"
        assert Docker(option).name == "docker"
        assert Python(option).name == "python"
        assert Node(option).name == "nodejs"
        assert Rust(option).name == "rust"
        assert Golang(option).name == "golang"


def test_tmux() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = TMux(option)
        assert r.run().code == ExitCode.SUCCESS
        dst = option.dest_dir / ".tmux.conf"
        _check_file_exist(dst)
        _check_has_markers(dst)
        assert r.run().code == ExitCode.SUCCESS  # 再実行でマーカー範囲が更新される


def test_vimperatorrc() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = Vimperator(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".vimperatorrc")
        assert r.run().code == ExitCode.SUCCESS


def test_gdb() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Gdb(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".gdbinit")
        assert r.run().code == ExitCode.SUCCESS


def test_fvwm2() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Fvwm2(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".fvwm2rc")
        assert r.run().code == ExitCode.SUCCESS


def test_git() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = Git(option)
        assert r.run().code == ExitCode.SUCCESS
        dst = option.dest_dir / ".gitconfig"
        _check_file_exist(dst)
        _check_has_markers(dst)
        _check_file_exist(option.dest_dir / ".config" / "git" / "ignore")
        # 再実行でもシンボリックリンク再作成 + マーカー範囲更新でSUCCESS
        assert r.run().code == ExitCode.SUCCESS


def test_zsh() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Zsh(option)
        assert r.run().code == ExitCode.SUCCESS
        zshrc = option.dest_dir / ".zshrc"
        zshenv = option.dest_dir / ".zshenv"
        _check_file_exist(zshrc)
        _check_file_exist(zshenv)
        _check_has_markers(zshrc)
        _check_has_markers(zshenv)
        assert r.run().code == ExitCode.SUCCESS


def test_vim() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = Vim(option)
        assert r.run().code == ExitCode.SUCCESS
        dst = option.dest_dir / ".vimrc"
        _check_file_exist(dst)
        _check_has_markers(dst, comment_prefix='"')
        _check_file_exist(option.dest_dir / ".vim")
        assert r.run().code == ExitCode.SUCCESS  # 再実行でマーカー範囲が更新される


def test_neovim() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = NeoVim(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".local" / "share" / "nvim" / "site" / "autoload" / "plug.vim")
        dst = option.dest_dir / ".config" / "nvim" / "init.vim"
        _check_file_exist(dst)
        _check_has_markers(dst, comment_prefix='"')
        assert r.run().code == ExitCode.SUCCESS  # 再実行でマーカー範囲が更新される


def test_command() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = CommandLineHelper(option)
        assert r.run().code == ExitCode.SUCCESS
        assert r.run().code == ExitCode.SUCCESS


def test_docker() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Docker(option)
        assert r.run().code == ExitCode.SUCCESS
        if sys.platform != "darwin":
            _check_file_exist(option.dest_dir / ".docker" / "cli-plugins" / "docker-buildx")
        _check_file_exist(option.dest_dir / "bin" / "docker-compose")
        assert r.run().code == ExitCode.SUCCESS


def test_python() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Python(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".pyenv")
        assert r.run().code == ExitCode.SUCCESS


def test_terraform() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Terraform(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".tfenv")
        # 再実行: .tfenvが既に存在するのでcloneされないがSUCCESSを返す
        assert r.run().code == ExitCode.SUCCESS


def test_node() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Node(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".nvm")
        assert r.run().code == ExitCode.SKIP


def test_rust() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=False)
        r = Rust(option)
        assert r.run().code == ExitCode.SUCCESS
        assert r.run().code == ExitCode.SUCCESS


def test_golang() -> None:
    with tempfile.TemporaryDirectory() as d:
        option = Option(dest_dir=pathlib.Path(d), redownload=True)
        r = Golang(option)
        assert r.run().code == ExitCode.SUCCESS
        _check_file_exist(option.dest_dir / ".golang" / "bin" / "go")
        assert r.run().code == ExitCode.SUCCESS
