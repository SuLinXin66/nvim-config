-- keymaps.lua 在 Lazy.nvim 启动之前自动加载。
-- 始终设置的默认按键映射: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- 在此添加其他按键映射
local keymap = vim.keymap

-- 1. 窗口管理与分屏
keymap.set("n", "s", "<nop>") -- 彻底禁用 s 原有功能
keymap.set("n", "sv", ":vsp<CR>", { desc = "垂直分屏" })
keymap.set("n", "sh", ":sp<CR>", { desc = "水平分屏" })
keymap.set("n", "sc", "<C-w>c", { desc = "关闭当前窗口" })
keymap.set("n", "so", "<C-w>o", { desc = "关闭其他窗口" })

-- 窗口跳转 (Alt + hjkl)
keymap.set("n", "<A-h>", "<C-w>h")
keymap.set("n", "<A-j>", "<C-w>j")
keymap.set("n", "<A-k>", "<C-w>k")
keymap.set("n", "<A-l>", "<C-w>l")

-- 【补全】窗口比例控制
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "窗口左缩" })
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "窗口右扩" })
keymap.set("n", "<C-Down>", ":resize +2<CR>", { desc = "窗口下扩" })
keymap.set("n", "<C-Up>", ":resize -2<CR>", { desc = "窗口上缩" })

-- 快速比例控制 (s 组合键)
keymap.set("n", "s,", ":vertical resize -20<CR>")
keymap.set("n", "s.", ":vertical resize +20<CR>")
keymap.set("n", "sj", ":resize +10<CR>")
keymap.set("n", "sk", ":resize -10<CR>")
keymap.set("n", "s=", "<C-w>=", { desc = "等比例排列" })

-- 2. 终端相关
keymap.set("n", "<leader>t", ":sp | terminal<CR>", { desc = "水平终端" })
keymap.set("n", "<leader>vt", ":vsp | terminal<CR>", { desc = "垂直终端" })
keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "退出终端模式" })
keymap.set("t", "<A-h>", [[<C-\><C-n><C-w>h]])
keymap.set("t", "<A-j>", [[<C-\><C-n><C-w>j]])
keymap.set("t", "<A-k>", [[<C-\><C-n><C-w>k]])
keymap.set("t", "<A-l>", [[<C-\><C-n><C-w>l]])

-- 3. 可视模式操作 (Visual)
keymap.set("v", "<", "<gv") -- 缩进后自动重新选中
keymap.set("v", ">", ">gv")
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "文本下移" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "文本上移" })
keymap.set("v", "p", '"_dP', { desc = "粘贴不覆盖剪贴板" })

-- 4. 移动与跳转
keymap.set("n", "<C-j>", "4j")
keymap.set("n", "<C-k>", "4k")
keymap.set("n", "<C-u>", "9k")
keymap.set("n", "<C-d>", "9j")
keymap.set("i", "<C-h>", "<ESC>I", { desc = "行首" })
keymap.set("i", "<C-l>", "<ESC>A", { desc = "行尾" })

-- 5. 退出
keymap.set("n", "q", ":q<CR>")
keymap.set("n", "qq", ":q!<CR>")
keymap.set("n", "Q", ":qa!<CR>")

-- 6. BufferLine (针对你的配置习惯)
-- 左右 Tab 切换 (对应你原先的 BufferLineCyclePrev/Next)
keymap.set("n", "<C-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "上一个标签" })
keymap.set("n", "<C-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "下一个标签" })

-- 关闭当前标签
-- 注意：LazyVim 默认集成了一个更好用的 Snacks.bufdelete()，
-- 它在关闭标签时不会导致窗口布局乱掉（类似你原先 Bdelete 的功能）。
keymap.set("n", "<C-w>", function()
	Snacks.bufdelete()
end, { desc = "关闭当前标签" })

-- 7.
-- 使用 LazyVim 默认的文件查找 (通常是 Snacks.picker.files 或 Telescope)
keymap.set("n", "<C-p>", function()
	-- LazyVim 提供了一个统一的入口，会根据你的配置自动选择最快的 picker
	LazyVim.pick("files")()
end, { desc = "查找文件 (LazyVim)" })

-- 使用 LazyVim 默认的全局搜索 (Live Grep)
keymap.set("n", "<C-f>", function()
	LazyVim.pick("live_grep")()
end, { desc = "全局搜索 (LazyVim)" })

