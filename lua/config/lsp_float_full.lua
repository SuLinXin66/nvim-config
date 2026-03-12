local M = {}

-- =========================================================
-- 状态管理
-- =========================================================
-- 这里保存当前“受管浮窗”的状态。
-- 之所以需要状态，是为了在关闭、跳转、自动同步标题时，
-- 能准确知道当前哪个浮窗是我们创建和管理的。
local state = {
  win = nil, -- 当前受管浮窗的 window id
  buf = nil, -- 当前受管浮窗的 buffer id
  augroup = nil, -- 用于管理自动命令的 augroup id
}

-- =========================================================
-- 常量配置
-- =========================================================
local FLOAT_MARK = "lsp_float_browser"
local AUGROUP_NAME = "LspFloatBrowser"

local UI = {
  width_ratio = 0.82,
  height_ratio = 0.78,
  min_width = 40,
  min_height = 10,
  border = "rounded",
  footer = " q close • <CR> open ",
}

-- =========================================================
-- 基础工具函数
-- =========================================================

---判断窗口是否有效
---@param win integer|nil
---@return boolean
local function is_valid_win(win)
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

---判断 buffer 是否有效
---@param buf integer|nil
---@return boolean
local function is_valid_buf(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

---判断一个窗口是否为浮窗
---@param win integer|nil
---@return boolean
local function is_float_win(win)
  if not is_valid_win(win) then
    return false
  end
  local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
  return ok and cfg ~= nil and cfg.relative ~= ""
end

---判断一个浮窗是否是“本模块管理的浮窗”
---@param win integer|nil
---@return boolean
local function is_managed_float(win)
  if not is_float_win(win) then
    return false
  end

  local ok, mark = pcall(function()
    return vim.w[win][FLOAT_MARK] == true
  end)

  return ok and mark
end

---获取 buffer 对应的文件名（仅文件名，不带路径）
---@param bufnr integer
---@return string
local function short_buf_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == nil or name == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":t")
end

---获取 buffer 对应的完整文件路径
---@param bufnr integer
---@return string
local function full_buf_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == nil or name == "" then
    return ""
  end
  return name
end

---统一通知函数
---@param msg string
---@param level integer|nil
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

-- =========================================================
-- LSP Location 查询
-- =========================================================

---从 LSP 返回结果中取第一个可用 location
---支持 Location 和 LocationLink 两种返回类型
---@param method string
---@param timeout_ms integer|nil
---@return table|nil
local function first_location(method, timeout_ms)
  local params = vim.lsp.util.make_position_params(0, "utf-8")
  local results = vim.lsp.buf_request_sync(0, method, params, timeout_ms or 1500)

  if not results then
    return nil
  end

  for _, res in pairs(results) do
    local result = res.result
    if result and not vim.tbl_isempty(result) then
      local loc = result[1] or result

      -- LocationLink 转为标准 Location 结构，方便统一处理
      if loc.targetUri then
        loc = {
          uri = loc.targetUri,
          range = loc.targetSelectionRange or loc.targetRange,
        }
      end

      return loc
    end
  end

  return nil
end

---根据 location 取出目标跳转信息
---@param loc table
---@return string fname, integer line, integer col
local function location_to_target(loc)
  local fname = vim.uri_to_fname(loc.uri)

  local line = 1
  local col = 0
  if loc.range and loc.range.start then
    line = (loc.range.start.line or 0) + 1
    col = loc.range.start.character or 0
  end

  return fname, line, col
end

-- =========================================================
-- 自动命令管理
-- =========================================================

---清理当前模块使用的自动命令组
local function clear_autocmd()
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end
end

-- =========================================================
-- 浮窗 UI 管理
-- =========================================================

---根据编辑器当前尺寸计算浮窗尺寸和位置
---@return table
local function calc_float_layout()
  local width = math.floor(vim.o.columns * UI.width_ratio)
  local height = math.floor(vim.o.lines * UI.height_ratio)
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  return {
    width = math.max(width, UI.min_width),
    height = math.max(height, UI.min_height),
    row = math.max(row, 0),
    col = math.max(col, 0),
  }
end

---设置浮窗通用窗口选项
---@param win integer
local function configure_float_window(win)
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldenable = false
end

---设置浮窗内 buffer 的通用选项
---@param bufnr integer
local function configure_float_buffer(bufnr)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = "wipe"
end

---更新受管浮窗的标题和 footer
---这个函数是为了解决：
---1. 在浮窗里继续 gd / gy / gpf / gpF 时标题同步
---2. 在浮窗里按 <C-o> / <C-i> 切 buffer 时标题不同步的问题
---@param win integer
local function update_float_decorations(win)
  if not is_managed_float(win) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(win)
  if not is_valid_buf(bufnr) then
    return
  end

  local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
  if not ok or not cfg then
    return
  end

  cfg.title = " " .. short_buf_name(bufnr) .. " "
  cfg.title_pos = "center"
  cfg.footer = UI.footer
  cfg.footer_pos = "right"

  pcall(vim.api.nvim_win_set_config, win, cfg)
end

---关闭当前受管浮窗
---这里优先关闭“当前所在浮窗”，因为在 <C-o> / <C-i> 之后，
---state.win 和当前实际浮窗不一定完全同步。
local function close_float()
  local curwin = vim.api.nvim_get_current_win()

  if is_managed_float(curwin) then
    vim.api.nvim_win_close(curwin, true)
    if state.win == curwin then
      state.win = nil
      state.buf = nil
    end
    clear_autocmd()
    return
  end

  if is_managed_float(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
  state.buf = nil
  clear_autocmd()
end

---将当前浮窗里的光标位置真正打开到普通编辑窗口
local function open_current_location()
  local curwin = vim.api.nvim_get_current_win()
  if not is_valid_win(curwin) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(curwin)
  if not is_valid_buf(bufnr) then
    return
  end

  local fname = full_buf_name(bufnr)
  if fname == "" then
    notify("当前浮窗没有对应文件，无法打开", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(curwin)

  close_float()
  vim.cmd("edit " .. vim.fn.fnameescape(fname))
  pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end

-- =========================================================
-- 浮窗内键位绑定
-- =========================================================

---给当前浮窗里的 buffer 绑定专用键位
---注意：必须是 buffer-local。
---因为浮窗里按 <C-o> / <C-i> 后 buffer 可能变化，
---所以我们后面会配合 BufEnter/WinEnter 自动重新绑定。
---@param bufnr integer
local function attach_float_keymaps(bufnr)
  local opts = { buffer = bufnr, nowait = true, silent = true }

  -- 关闭浮窗
  vim.keymap.set("n", "q", close_float, opts)

  -- 在浮窗中继续沿着 definition 浏览
  vim.keymap.set("n", "gpf", function()
    M.open_target_buffer_float("textDocument/definition")
  end, opts)

  vim.keymap.set("n", "gpF", function()
    M.open_target_buffer_float("textDocument/typeDefinition")
  end, opts)

  -- 兼容你下意识按原生导航键
  vim.keymap.set("n", "gd", function()
    M.open_target_buffer_float("textDocument/definition")
  end, opts)

  vim.keymap.set("n", "gy", function()
    M.open_target_buffer_float("textDocument/typeDefinition")
  end, opts)

  -- 真正打开当前浮窗所在位置
  vim.keymap.set("n", "<CR>", open_current_location, opts)
end

---确保当前受管浮窗的 buffer 始终拥有正确键位和标题
---这是解决：
---1. <C-o> 后 q 失效
---2. <C-o> 后标题不更新
---的关键入口。
local function sync_current_float_context()
  local curwin = vim.api.nvim_get_current_win()
  if not is_managed_float(curwin) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(curwin)
  if not is_valid_buf(bufnr) then
    return
  end

  state.win = curwin
  state.buf = bufnr

  update_float_decorations(curwin)
  attach_float_keymaps(bufnr)
end

---为当前受管浮窗注册自动同步逻辑
local function setup_float_autocmd()
  clear_autocmd()

  state.augroup = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })

  -- 当浮窗内发生 buffer/window 切换时，重新同步标题和按键
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = state.augroup,
    callback = function()
      sync_current_float_context()
    end,
  })

  -- 当受管浮窗被关闭时，清理状态
  vim.api.nvim_create_autocmd("WinClosed", {
    group = state.augroup,
    callback = function(args)
      local closed = tonumber(args.match)
      if state.win and closed == state.win then
        state.win = nil
        state.buf = nil
        clear_autocmd()
      end
    end,
  })
end

-- =========================================================
-- 对外主功能：打开 definition/typeDefinition 所在文件全文浮窗
-- =========================================================

---以浮窗形式打开目标位置所在文件的完整内容
---method 常见值：
---  - textDocument/definition
---  - textDocument/typeDefinition
---@param method string
function M.open_target_buffer_float(method)
  local loc = first_location(method, 1500)
  if not loc or not loc.uri then
    notify("No target found", vim.log.levels.WARN)
    return
  end

  -- 每次新开前，先关闭旧浮窗，保证界面干净
  close_float()

  local fname, line, col = location_to_target(loc)
  local bufnr = vim.fn.bufadd(fname)
  vim.fn.bufload(bufnr)

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    notify("Failed to load buffer: " .. fname, vim.log.levels.ERROR)
    return
  end

  local layout = calc_float_layout()

  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = layout.row,
    col = layout.col,
    width = layout.width,
    height = layout.height,
    style = "minimal",
    border = UI.border,
    title = " " .. short_buf_name(bufnr) .. " ",
    title_pos = "center",
    footer = UI.footer,
    footer_pos = "right",
  })

  state.win = win
  state.buf = bufnr

  -- 给浮窗打标记，后续识别“是不是本模块创建的浮窗”就靠它
  vim.w[win][FLOAT_MARK] = true

  configure_float_window(win)
  configure_float_buffer(bufnr)

  -- 将光标移动到目标定义附近，并居中展示
  vim.api.nvim_win_set_cursor(win, { line, col })
  vim.api.nvim_set_current_win(win)
  vim.cmd("normal! zz")

  attach_float_keymaps(bufnr)
  setup_float_autocmd()
end

return M
