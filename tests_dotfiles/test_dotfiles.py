from dotfiles import Runner
from dotfiles.logics import TMux


def test_tmux() -> None:
    r = Runner()
    r.add_logic(TMux())
    r.run()
