-- このファイルのディレクトリを取得（シンボリックリンクを解決）
local script_path = debug.getinfo(1, "S").source:sub(2)
local real_path = vim.fn.resolve(script_path)
local script_dir = vim.fn.fnamemodify(real_path, ":p:h")

-- 基本設定は .vimrc から読み込む
vim.g.use_neovim = 1
vim.cmd('source ' .. script_dir .. '/../.vimrc')

-- lazy.nvim のブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- プラグイン読み込み（lua/plugins/ 内の .lua ファイルを自動読み込み）
require("lazy").setup("plugins")

-- プラグイン設定（VimScript）
vim.cmd('source ' .. script_dir .. '/plugin-config.vim')
