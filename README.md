# dotfiles

Install dot files for curekoshimizu (this script author).
For example, .vimrc, .gitconfig, .zshrc, and so on.


## How to run

Run

```
poetry run scripts/installer.py
```

or

```
./dot_installer.bash
```

installer.py is the body script.
On the other hand, dot_installer.bash is a wrapper script of installer.py, which will take care of `curl` and `poetry` exist.
If these commands are not found, dot_installer.bash will ask you to install them.

## TODO

* GL
* cuda
* npm
* golang
* rust

## LICENSE

MIT License
