-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
opt.listchars = { space = "·" }
opt.relativenumber = false

vim.o.winborder = "rounded"

-- fix: system clipboard
do
  local osc52 = require("vim.ui.clipboard.osc52")

  vim.g.clipboard = {
    name = "native-or-osc52",
    copy = {
      ["+"] = function(lines, regtype)
        -- 桌面有 provider 时这句会写入系统剪贴板（更快）
        pcall(vim.fn.setreg, "+", lines, regtype)
        -- docker/ssh 无 provider 时靠这句把内容送到宿主机剪贴板
        osc52.copy("+")(lines, regtype)
      end,
      ["*"] = function(lines, regtype)
        pcall(vim.fn.setreg, "*", lines, regtype)
        osc52.copy("*")(lines, regtype)
      end,
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }

  -- 可选：把 LazyVim 的 leader 复制也强制走系统剪贴板寄存器
  vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { noremap = true, silent = true })
  vim.keymap.set("n", "<leader>Y", '"+yy', { noremap = true, silent = true })
end

vim.opt.termguicolors = true

local function make_transparent()
  local groups = {
    --"Normal",
    --"NormalNC",
    --"SignColumn",
    --"EndOfBuffer",
    --"MsgArea",
    --"FloatBorder",
    --"NormalFloat",
    --"Pmenu",
    --"PmenuSel",
    --"TelescopeNormal",
    --"TelescopeBorder",
    --"NeoTreeNormal",
    --"NeoTreeNormalNC",
    --"WhichKeyFloat",
    --"LazyNormal",
    "CursorLine",
    "CursorLine",

    -- Tabline / Bufferline / Winbar
    --"TabLine",
    --"TabLineFill",
    --"TabLineSel",
    --"WinBar",
    --"WinBarNC",

    -- Statusline / Lualine
    --"StatusLine",
    --"StatusLineNC",

    -- Popup / 输入框 / 补全
    --"Pmenu",
    --"PmenuSel",
    --"PmenuSbar",
    --"PmenuThumb",

    -- 分割线/边框
    --"VertSplit",
    --"WinSeparator",

    -- 命令行/提示
    --"MsgArea",
    --"ModeMsg",
    --"MoreMsg",
    --"Question",

    -- 搜索/匹配高亮（可选）
    --"Search",
    --"IncSearch",
    --"CurSearch",

    --"NeoTreeTitleBar",
    --"NeoTreeFloatBorder",
    --"NeoTreeFloatTitle",
    --"NeoTreeEndOfBuffer",

    --"FloatTitle",
    --"PromptNormal",
    --"PromptBorder",
  }
  for _, g in ipairs(groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end

  vim.opt.cursorline = true
  vim.opt.cursorlineopt = "number" -- 只高亮行号（最不突兀）
  --------------------------------------------------
  -- NeoTree 专项修复
  --------------------------------------------------
  vim.api.nvim_set_hl(0, "NeoTreeTitleBar", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "none", fg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeVertSplit", { bg = "none", fg = "none" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "WinBar", { bg = "none" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "none" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = make_transparent,
})

-- 关键：确保“启动后也执行一次”（避免错过第一次 colorscheme）
vim.schedule(make_transparent)
