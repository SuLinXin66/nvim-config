-- ~/.config/nvim/lua/plugins/dap-breakpoints.lua
return {
  -- 1) 禁用 LazyVim 默认的断点键（否则后加载会覆盖你）
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", false },
      { "<leader>dB", false },
      { "<leader>dl", false },
      { "<leader>dC", false },
    },
  },

  -- 2) 持久化断点：按项目隔离 + 项目切换自动切换断点集合
  {
    "Weissle/persistent-breakpoints.nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
      -- LazyVim 一般已内置 project.nvim；加上依赖更稳
      "ahmedkhalf/project.nvim",
    },

    -- 必须在读文件前加载，否则 BufReadPost 的自动恢复会错过
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local dap_ok, dap = pcall(require, "dap")
      if not dap_ok then
        return
      end

      local function get_project_root()
        -- project.nvim：LazyVim 常用的项目根判定器
        local ok, project = pcall(require, "project_nvim.project")
        if ok and project and project.get_project_root then
          local root = project.get_project_root()
          if root and root ~= "" then
            return root
          end
        end

        -- 兜底：用当前工作目录
        local cwd = vim.loop.cwd()
        if cwd and cwd ~= "" then
          return cwd
        end
      end

      require("persistent-breakpoints").setup({
        save_dir = vim.fn.stdpath("data") .. "/dap-breakpoints",
        load_breakpoints_event = { "BufReadPost" },

        -- 关键：按“项目根目录”作为断点集合的 key
        key = function(bufnr)
          local root = get_project_root()
          if root then
            return root
          end
          return vim.api.nvim_buf_get_name(bufnr)
        end,
      })

      local api = require("persistent-breakpoints.api")

      -- 兜底：有些启动方式（session/Project打开）会让时序很怪
      -- VimEnter 主动 load 一次，保证“第一次进入就恢复”
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          pcall(api.load_breakpoints)
        end,
      })

      -- 深度联动：切换项目时自动切换断点集合
      -- ProjectEnter 是 project.nvim 发出的 User 事件
      vim.api.nvim_create_autocmd("User", {
        pattern = "ProjectEnter",
        callback = function()
          -- 先清空旧项目断点，再加载新项目断点
          dap.clear_breakpoints()
          api.load_breakpoints()
        end,
      })
    end,

    -- 3) 只覆盖“断点相关”的键：其余调试键仍用 LazyVim 默认
    keys = {
      {
        "<leader>db",
        function()
          require("persistent-breakpoints.api").toggle_breakpoint()
        end,
        desc = "DAP: Toggle Breakpoint (persistent, project)",
      },
      {
        "<leader>dB",
        function()
          require("persistent-breakpoints.api").set_conditional_breakpoint()
        end,
        desc = "DAP: Conditional Breakpoint (persistent, project)",
      },
      {
        "<leader>dl",
        function()
          require("persistent-breakpoints.api").set_log_point()
        end,
        desc = "DAP: Log Point (persistent, project)",
      },
      {
        "<leader>dC",
        function()
          require("persistent-breakpoints.api").clear_all_breakpoints()
        end,
        desc = "DAP: Clear Breakpoints (persistent, project)",
      },
    },
  },

  -- 4) 可选：避免“断点已恢复但左侧列不显示”的错觉
  -- 放这儿最省事：任何情况下强制显示 signcolumn
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.opt.signcolumn = "yes"
    end,
  },
}
