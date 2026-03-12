local M = {}

local state = {
  win = nil,
  buf = nil,
}

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

      -- LocationLink -> Location
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

local function close_float()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

function M.open_target_buffer_float(method)
  local loc = first_location(method, 1500)
  if not loc or not loc.uri then
    vim.notify("No target found", vim.log.levels.WARN)
    return
  end

  close_float()

  local fname = vim.uri_to_fname(loc.uri)
  local bufnr = vim.fn.bufadd(fname)
  vim.fn.bufload(bufnr)

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.notify("Failed to load buffer: " .. fname, vim.log.levels.ERROR)
    return
  end

  local width = math.floor(vim.o.columns * 0.82)
  local height = math.floor(vim.o.lines * 0.78)
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local title = " " .. vim.fn.fnamemodify(fname, ":t") .. " "
  local footer = " q / <Esc> close "

  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = math.max(row, 0),
    col = math.max(col, 0),
    width = math.max(width, 40),
    height = math.max(height, 10),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    footer = footer,
    footer_pos = "right",
  })

  state.win = win
  state.buf = bufnr

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldenable = false

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buflisted = false

  -- 跳到定义附近
  local target_line = 1
  local target_col = 0
  if loc.range and loc.range.start then
    target_line = (loc.range.start.line or 0) + 1
    target_col = loc.range.start.character or 0
  end

  vim.api.nvim_win_set_cursor(win, { target_line, target_col })

  -- 居中一下
  vim.cmd("normal! zz")

  local opts = { buffer = bufnr, nowait = true, silent = true }
  vim.keymap.set("n", "q", close_float, opts)
  vim.keymap.set("n", "<Esc>", close_float, opts)

  -- 回车：真的跳过去
  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    close_float()
    vim.cmd("edit " .. vim.fn.fnameescape(fname))
    pcall(vim.api.nvim_win_set_cursor, 0, cursor)
  end, opts)
end

return M
