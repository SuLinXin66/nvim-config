-- ~/.config/nvim/lua/plugins/terminal.lua
--
-- 说明：
-- 1. 不配置 lazygit：LazyVim 默认已经有
-- 2. Cursor Agent 相关操作统一收口到 <leader>tc 菜单里
-- 3. Cursor Agent 默认底部常驻，不使用悬浮窗口
-- 4. 普通 shell 保留底部和悬浮两种
-- 5. yazi 使用 yazi.nvim，从当前文件位置打开，悬浮显示

---@diagnostic disable: undefined-global

local rt = require("tools.runtime")

-- Snacks.terminal 窗口预设 ------------------------------------------------

local function float_win(title)
  return {
    position = "float",
    width = 0.88,
    height = 0.82,
    -- 透明背景下边框很重要，否则看不清窗口边界
    border = "rounded",
    title = title,
    title_pos = "center",
    -- 数字越大背景越暗
    backdrop = 60,
    wo = {
      winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title",
    },
  }
end

local function bottom_win()
  return {
    position = "bottom",
    height = 0.36,
  }
end

-- 终端打开通用入口 ---------------------------------------------------------

local function open_bottom(cmd, count)
  Snacks.terminal.focus(cmd, {
    cwd = rt.root(),
    count = count,
    interactive = true,
    auto_close = false,
    win = bottom_win(),
  })
end

local function open_float(cmd, count, title)
  Snacks.terminal.focus(cmd, {
    cwd = rt.root(),
    count = count,
    interactive = true,
    auto_close = true,
    win = float_win(title),
  })
end

-- Cursor Agent -------------------------------------------------------------

-- 统一显式传 --workspace，避免 cwd 和 Cursor Agent 的 workspace 判断不一致
local function cursor_agent_cmd(args)
  local workspace = vim.fn.shellescape(rt.root())
  local cmd = "cursor-agent --workspace " .. workspace

  if args and args ~= "" then
    cmd = cmd .. " " .. args
  end

  return rt.shell_cmd(cmd)
end

-- 不同操作使用不同 count，避免新建、列表、ask、plan 互相抢同一个终端
local function open_cursor_agent(args, count)
  if not rt.executable("cursor-agent") then
    return
  end

  open_bottom(cursor_agent_cmd(args), count)
end

local function cursor_agent_menu()
  local items = {
    { label = "新建 Cursor Agent 会话", args = "", count = 20 },
    { label = "进入 Cursor Agent 会话列表", args = "ls", count = 21 },
    { label = "继续上一次 Cursor Agent 会话", args = "--continue", count = 22 },
    { label = "Ask 模式：只读问答，不改代码", args = "--mode ask", count = 23 },
    { label = "Plan 模式：只读规划，不改代码", args = "--plan", count = 24 },
    { label = "查看登录状态", args = "status", count = 25 },
    { label = "查看可用模型", args = "models", count = 26 },
  }

  vim.ui.select(items, {
    prompt = "Cursor Agent",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    open_cursor_agent(choice.args, choice.count)
  end)
end

-- 批量 toggle 所有 Snacks 终端窗口
local function toggle_all_terminals()
  local terms = Snacks.terminal.list()
  if vim.tbl_isempty(terms) then
    return
  end

  local any_visible = false
  for _, term in pairs(terms) do
    if term:win_valid() then
      any_visible = true
      break
    end
  end

  for _, term in pairs(terms) do
    if any_visible then
      term:hide()
    else
      term:show()
    end
  end
end

-- =========================================================================
-- 插件配置
-- =========================================================================

return {
  {
    "folke/snacks.nvim",
    keys = {
      -- Cursor Agent
      {
        "<leader>tc",
        cursor_agent_menu,
        desc = "Cursor Agent Menu",
        mode = { "n", "t" },
      },

      {
        "<leader>tT",
        toggle_all_terminals,
        desc = "Toggle All Terminals",
        mode = { "n", "t" },
      },

      -- OpenAI / 普通终端
      {
        "<leader>to",
        function()
          if not rt.executable("openai") then
            return
          end
          open_bottom("openai", 30)
        end,
        desc = "Terminal OpenAI",
        mode = { "n", "t" },
      },

      {
        "<leader>tt",
        function()
          open_bottom(nil, 1)
        end,
        desc = "Terminal Shell",
        mode = { "n", "t" },
      },

      {
        "<leader>tf",
        function()
          open_float(nil, 2, " Terminal ")
        end,
        desc = "Terminal Float Shell",
        mode = { "n", "t" },
      },

      -- 常用 TUI 工具
      {
        "<leader>tb",
        function()
          if not rt.executable("btop") then
            return
          end
          open_float("btop", 40, " Btop ")
        end,
        desc = "Terminal Btop",
        mode = { "n", "t" },
      },
    },
  },

  -- yazi.nvim
  -- 比 Snacks.terminal("yazi") 更适合 Neovim：
  -- 从当前文件位置打开、选中文件直接回 nvim、支持恢复上一次会话
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>ty",
        "<cmd>Yazi<cr>",
        desc = "Yazi Current File",
        mode = { "n", "v" },
      },
      {
        "<leader>tY",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi Cwd",
      },
      {
        "<leader>tr",
        "<cmd>Yazi toggle<cr>",
        desc = "Yazi Resume",
      },
    },
    opts = {
      -- 不劫持目录打开，避免影响 LazyVim / Snacks explorer 的默认行为
      open_for_directories = false,
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_winblend = 0,
      yazi_floating_window_border = "rounded",
      keymaps = {
        show_help = "<f1>",
      },
    },
  },
}
