local opt = vim.opt
local g = vim.g

-- 1. 全局变量 (必须保留 g)
g.encoding = "UTF-8"
-- 如果你还没设 leader 键，通常在这里设：
-- g.mapleader = " "

-- 2. 编辑器选项 (统一使用 opt)
opt.fileencoding = "utf-8"

-- 移动与留白
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.colorcolumn = "80"

-- 缩进设置 (opt 会自动处理 bo 和 o 的同步)
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- 搜索
opt.hlsearch = false
opt.incsearch = true

-- 界面与交互
opt.cmdheight = 2
opt.autoread = true
opt.wrap = false
opt.hidden = true
opt.mouse = "a"
opt.whichwrap:append("<,>,[,]") -- 使用 append 避免覆盖默认值

-- 备份与性能
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.updatetime = 300
opt.timeoutlen = 500

-- 窗口分割
opt.splitbelow = true
opt.splitright = true

-- 补全与样式
opt.completeopt = { "menu", "menuone", "noselect", "noinsert" } -- 使用 table 写法
opt.pumheight = 10
opt.termguicolors = true
opt.background = "dark"
opt.showtabline = 2
opt.showmode = false

-- 不可见字符显示
opt.list = true
opt.listchars = { space = "." }
