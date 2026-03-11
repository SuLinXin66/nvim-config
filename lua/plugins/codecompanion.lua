return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- 可选：如果你装了 telescope，也能用 provider=telescope
      -- "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp", -- 用于聊天窗口的斜杠命令补全
      "ravitemer/codecompanion-history.nvim",
    },

    -- 关键：让 CodeCompanion 能稳定找到 Copilot token（hosts.json / apps.json）
    --（很多人 copilot adapter “没反应”就是 token path 没被找到）
    init = function()
      vim.env.CODECOMPANION_TOKEN_PATH = vim.fn.expand("~/.config")
    end,

    opts = function()
      -- LazyVim 默认是 fzf-lua（v0.14 起替代 telescope）。:contentReference[oaicite:1]{index=1}
      -- CodeCompanion 的 action palette 支持：default/telescope/mini_pick/snacks。:contentReference[oaicite:2]{index=2}
      local action_palette_provider = "default"
      if package.loaded["snacks"] or pcall(require, "snacks") then
        action_palette_provider = "snacks"
      elseif pcall(require, "telescope") then
        action_palette_provider = "telescope"
      end

      return {
        language = "Simplified Chinese (简体中文)", -- 这个设置会影响一些预设 prompt 的语言（比如 Code Explanation）。如果你喜欢英文 prompt，可以改成 "English" 或者干脆删掉这个字段。
        ----------------------------------------------------------------------
        -- ✅ 核心：所有策略都走 Copilot（你有 Pro，体验最好）
        -- CodeCompanion 已明确支持 Copilot，并给了标准写法。:contentReference[oaicite:3]{index=3}
        ----------------------------------------------------------------------
        strategies = {
          chat = {
            adapter = "copilot",
            -- slash command 的 picker：LazyVim 默认 fzf-lua
            slash_commands = {
              ["file"] = { opts = { provider = "fzf_lua" } },
              ["buffer"] = { opts = { provider = "fzf_lua" } },
              ["help"] = { opts = { provider = "fzf_lua" } },
              ["symbols"] = { opts = { provider = "fzf_lua" } },
            },
          },
          inline = { adapter = "copilot" },
          agent = { adapter = "copilot" },
        },

        ----------------------------------------------------------------------
        -- ✅ UI：Action Palette 贴合 LazyVim（有 snacks 用 snacks；否则 telescope；否则 vim.ui.select）
        ----------------------------------------------------------------------
        display = {
          action_palette = {
            provider = action_palette_provider,
          },
        },
        extensions = {
          history = {
            enabled = true,
            opts = {
              keymap = "gh",
              save_chat_keymap = "sc",
              auto_save = true,
              expiration_days = 0,
              picker = "snacks",
              continue_last_chat = true, -- 重启 nvim 后继续上次聊天
              delete_on_clearing_chat = false,
              dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            },
          },
        },
      }
    end,

    keys = {
      -- LazyVim 常见把 AI 放在 <leader>a
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI: CodeCompanion Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI: CodeCompanion Chat" },
      { "<leader>aC", "<cmd>CodeCompanionChat<cr>", desc = "AI: CodeCompanion Chat" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", desc = "AI: CodeCompanion Inline" },
      { "<leader>aC", "<cmd>CodeCompanionCmd<cr>", desc = "AI: CodeCompanion Cmd" },

      -- 选中一段代码后加进 chat（文档里也推荐类似工作流）。:contentReference[oaicite:4]{index=4}
      { "<leader>as", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI: Add selection to Chat" },
    },
  },
}
