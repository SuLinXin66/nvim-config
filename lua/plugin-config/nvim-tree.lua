local status, nvim_tree = pcall(require, "nvim-tree")
if not status then
  vim.notify("没有找到 nvim-tree")
  return
end

-- 1. 定义新的快捷键映射函数 (代替旧的 mappings.list)
local function my_on_attach(bufnr)
  local api = require("nvim-tree.api")

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- 默认快捷键 (保留你习惯的默认操作)
  api.config.mappings.default_on_attach(bufnr)

  -- 自定义快捷键：完全对应你原先的 pluginKeys.nvimTreeList
  vim.keymap.set('n', '<CR>', api.node.open.edit,              opts('Open'))
  vim.keymap.set('n', 'o',    api.node.open.edit,              opts('Open'))
  vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit,     opts('Open'))
  
  vim.keymap.set('n', 'v',    api.node.open.vertical,          opts('Vsplit'))
  vim.keymap.set('n', 'h',    api.node.open.horizontal,        opts('Split'))
  
  -- 对应旧版的 toggle_custom 和 toggle_dotfiles
  vim.keymap.set('n', 'i',    api.tree.toggle_custom_filter,   opts('Toggle Hidden'))
  vim.keymap.set('n', '.',    api.tree.toggle_hidden_filter,   opts('Toggle Dotfiles'))
  
  -- 文件操作
  vim.keymap.set('n', '<F5>', api.tree.reload,                 opts('Refresh'))
  vim.keymap.set('n', 'a',    api.fs.create,                   opts('Create'))
  vim.keymap.set('n', 'd',    api.fs.remove,                   opts('Delete'))
  vim.keymap.set('n', 'r',    api.fs.rename,                   opts('Rename'))
  vim.keymap.set('n', 'x',    api.fs.cut,                      opts('Cut'))
  vim.keymap.set('n', 'c',    api.fs.copy.node,                opts('Copy'))
  vim.keymap.set('n', 'p',    api.fs.paste,                    opts('Paste'))
  vim.keymap.set('n', 's',    api.node.run.system,             opts('System Open'))
end

-- 2. 插件配置
nvim_tree.setup({
  -- 绑定自定义快捷键
  on_attach = my_on_attach,
  
  git = {
    enable = false,
  },
  -- project plugin 配合项
  -- 改变当前工作目录时，同步更新 tree 的根目录
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = true, -- 原 update_cwd
  },
  filters = {
    dotfiles = true,
    custom = { 'node_modules' },
  },
  renderer = {
    -- 修正：旧版的 hide_root_folder 现在在这里
    root_folder_label = false, 
  },
  view = {
    width = 40,
    side = 'left',
    -- mappings 已经移动到 on_attach，这里保持干净即可
    number = false,
    relativenumber = false,
    signcolumn = 'yes',
  },
  actions = {
    open_file = {
      resize_window = true,
      quit_on_open = true,
    },
  },
})

-- 自动关闭 (保持原样)
vim.cmd([[
  autocmd BufEnter * ++nested if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif
]])
