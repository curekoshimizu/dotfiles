from dotfiles import Runner, TMux


def test_tmux() -> None:
    r = Runner()
    r.add_logic(TMux())
    r.run()
