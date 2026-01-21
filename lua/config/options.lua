-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
opt.listchars = { space = "·" }

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
