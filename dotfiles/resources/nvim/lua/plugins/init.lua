return {
  -- カラースキーム
  { "vim-scripts/dante.vim" },

  -- ステータスライン
  { "itchyny/lightline.vim" },

  -- ハイライト
  { "curekoshimizu/vim-quickhl" },

  -- 検索 (Ag)
  { "rking/ag.vim" },

  -- ファイラー
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        -- カラムの設定（サイズ、更新日時）
        columns = {
          "size",
          {
            "mtime",
            format = "%Y/%m/%d %H:%M",  -- 2026/01/10 16:07 形式
          },
        },
        -- キーマッピング
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-l>"] = "actions.select",        -- ディレクトリに入る/ファイルを開く
          ["<C-h>"] = "actions.parent",        -- 親ディレクトリに戻る
          ["."] = "actions.toggle_hidden",     -- 隠しファイル表示切り替え
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",       -- リフレッシュ
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = {
            callback = function()
              require("oil").open(vim.fn.expand("~"))
            end,
            desc = "Open home directory",
          },
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g\\"] = "actions.toggle_trash",
        },
        -- 隠しファイルを表示
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name)
            return name == ".." or name == ".DS_Store"
          end,
          -- デフォルトのソート順（ディレクトリ→ファイル、その中で更新日時の降順）
          sort = {
            { "type", "asc" },   -- ディレクトリが先
            { "mtime", "desc" }, -- その中で更新日時の降順
          },
        },
      })

      -- nvim . でもプレビューを自動で開く（上30%にプレビュー表示）
      vim.api.nvim_create_autocmd("User", {
        pattern = "OilEnter",
        callback = vim.schedule_wrap(function(args)
          local oil = require("oil")
          if vim.api.nvim_get_current_buf() == args.data.buf and oil.get_cursor_entry() then
            oil.open_preview({ horizontal = true, split = "aboveleft" }, function()
              -- プレビューウィンドウの高さを30%に設定
              vim.schedule(function()
                local util = require("oil.util")
                local preview_win_id = util.get_preview_win()
                if preview_win_id then
                  local total_height = vim.o.lines
                  local preview_height = math.floor(total_height * 0.3)
                  vim.api.nvim_win_set_height(preview_win_id, preview_height)
                end
              end)
            end)
          end
        end),
      })
    end,
  },

  -- Obsidian（環境変数 OBSIDIAN_NOTES_PATH が設定されている場合のみ）
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = false,
    cond = vim.env.OBSIDIAN_NOTES_PATH ~= nil,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        { name = "notes", path = vim.env.OBSIDIAN_NOTES_PATH or "" },
      },
      ui = {
        enable = true,
      },
      -- デフォルトの保存先を 00_Raw にする
      notes_subdir = "00_Raw",
      -- Daily Notes の設定
      daily_notes = {
        folder = "00_Raw",
        date_format = "%Y_%m_%d_Daily",
      },
      -- ファイル名を YYYY_MM_DD_タイトル の形式にする
      -- タイトルが空の場合、または重複時は unixtime を追加
      note_id_func = function(title)
        local date_part = os.date("%Y_%m_%d")
        local vault_path = vim.env.OBSIDIAN_NOTES_PATH or ""
        local notes_dir = vault_path .. "/00_Raw"

        local function file_exists(name)
          local f = io.open(name, "r")
          if f then f:close() return true else return false end
        end

        -- タイトルが空の場合は unixtime のみ
        if title == nil or title == "" then
          return date_part .. "_" .. os.time()
        end

        local safe_title = title:gsub(" ", "_"):gsub("[^A-Za-z0-9_ぁ-んァ-ン一-龯]", "")

        -- まず unixtime なしで試す
        local base_id = date_part .. "_" .. safe_title
        local base_path = notes_dir .. "/" .. base_id .. ".md"

        if not file_exists(base_path) then
          return base_id
        else
          -- 重複時は unixtime を追加
          return date_part .. "_" .. os.time() .. "_" .. safe_title
        end
      end,
    },
    init = function()
      vim.opt.conceallevel = 2

      -- カスタム ObsidianTodayWithTemplate コマンド
      vim.api.nvim_create_user_command("ObsidianTodayWithTemplate", function()
        local vault_path = vim.env.OBSIDIAN_NOTES_PATH or ""
        local notes_dir = vault_path .. "/00_Raw"

        local function file_exists(path)
          local f = io.open(path, "r")
          if f then f:close() return true else return false end
        end

        local function read_file(path)
          local f = io.open(path, "r")
          if not f then return nil end
          local content = f:read("*all")
          f:close()
          return content
        end

        local function write_file(path, content)
          local f = io.open(path, "w")
          if not f then return false end
          f:write(content)
          f:close()
          return true
        end

        -- 今日の日付
        local today = os.time()
        local today_filename = os.date("%Y_%m_%d_Daily", today) .. ".md"
        local today_path = notes_dir .. "/" .. today_filename

        -- ファイルが既に存在する場合はそのまま開く
        if file_exists(today_path) then
          vim.cmd("edit " .. today_path)
          return
        end

        -- 過去7日間のファイルを探す
        local found_content = nil
        local source_filename = nil
        local days_ago = nil
        for i = 1, 7 do
          local past_time = today - (i * 86400) -- 86400秒 = 1日
          local past_filename = os.date("%Y_%m_%d_Daily", past_time) .. ".md"
          local past_path = notes_dir .. "/" .. past_filename
          if file_exists(past_path) then
            found_content = read_file(past_path)
            source_filename = past_filename
            days_ago = i
            break
          end
        end

        -- コンテンツを決定
        local content
        if found_content then
          -- 前日のファイルの frontmatter の id を今日の日付に更新
          local today_id = os.date("%Y_%m_%d_Daily", today)
          content = found_content:gsub("id: %d%d%d%d_%d%d_%d%d_Daily", "id: " .. today_id)
          vim.notify("Copied from: " .. source_filename .. " (" .. days_ago .. "日前)", vim.log.levels.INFO)
        else
          -- テンプレートを使用
          local today_id = os.date("%Y_%m_%d_Daily", today)
          content = "---\nid: " .. today_id .. "\naliases: []\ntags:\n  - daily-notes\n---\n"
          vim.notify("Created from template", vim.log.levels.INFO)
        end

        -- ファイルを作成して開く
        write_file(today_path, content)
        vim.cmd("edit " .. today_path)
      end, {})
    end,
  },

  -- EasyMotion
  {
    "easymotion/vim-easymotion",
    lazy = false,
    config = function()
      -- デフォルトマッピングを無効化
      vim.g.EasyMotion_do_mapping = 0
      -- キーマッピング設定（vim側と同じ）
      vim.keymap.set('n', 'e', '<Plug>(easymotion-bd-w)', { noremap = false })
      vim.keymap.set('n', 'E', '<Plug>(easymotion-s2)', { noremap = false })
    end,
  },
}
