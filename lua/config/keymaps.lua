-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local keymap = vim.keymap.set
keymap("i", "jj", "<Esc>", { desc = "Exit insert mode with jj" })
keymap("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })

-- 目标：
-- 1) y 仍然走系统剪贴板（LazyVim 的 clipboard=unnamedplus 保持不动）
-- 2) d / c 系列默认不污染剪贴板（写入黑洞寄存器）
-- Delete: do not affect registers/clipboard
keymap({ "n", "x" }, "d", '"_d', { desc = "Delete (black hole)" })
keymap({ "n", "x" }, "D", '"_D', { desc = "Delete line-end (black hole)" })

-- Change: do not affect registers/clipboard
keymap({ "n", "x" }, "c", '"_c', { desc = "Change (black hole)" })
keymap({ "n", "x" }, "C", '"_C', { desc = "Change line-end (black hole)" })

-- 可选：x / X 也不污染（通常本来就是小删除，但开了 unnamedplus 后也可能影响剪贴板）
keymap({ "n", "x" }, "x", '"_x', { desc = "Char delete (black hole)" })
keymap({ "n", "x" }, "X", '"_X', { desc = "Backspace delete (black hole)" })

keymap({ "n", "x" }, "Q", "<CMD>:qa<CR>", { desc = " quick quit all" })
keymap({ "n", "x" }, "qq", "<CMD>:q<CR>", { desc = " quick quit" })

-- keymap("n", "<M-S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
-- keymap("n", "<M-S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

keymap({ "n", "x", "o" }, "<S-H>", "^", { desc = "shift line left" })
keymap({ "n", "x", "o" }, "<S-L>", "$", { desc = "shift line right" })

local wk = require("which-key")

wk.add({
  { "<leader>W", group = "copy file" },
})

local function copy(text)
  vim.fn.setreg("+", text)
  vim.notify("Copied: " .. text)
end

local function rel()
  return vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
end

local function abs()
  return vim.fn.fnamemodify(vim.fn.expand("%"), ":p")
end

local function name()
  return vim.fn.expand("%:t")
end

local function dir()
  return vim.fn.expand("%:p:h")
end

local function fileline()
  return rel() .. ":" .. vim.fn.line(".")
end

keymap("n", "<leader>Wf", function()
  copy(name())
end, { desc = "Copy filename" })
keymap("n", "<leader>Wp", function()
  copy(rel())
end, { desc = "Copy relative path" })
keymap("n", "<leader>WP", function()
  copy(abs())
end, { desc = "Copy absolute path" })
keymap("n", "<leader>Wl", function()
  copy(fileline())
end, { desc = "Copy file:line" })
keymap("n", "<leader>Wd", function()
  copy(dir())
end, { desc = "Copy directory" })
