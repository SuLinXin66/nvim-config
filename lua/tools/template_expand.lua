local M = {}

-- 构建默认上下文
-- @param config table table|nil 配置项
-- @retirm table<string, string>
local function build_context(config)
  local cwd = (config and config.cwd) or vim.fn.getcwd()
  local file = vim.api.nvim_buf_get_name(0)

  return {
    workspaceFolder = cwd,
    workspaceFolderBasename = vim.fn.fnamemodify(cwd, ":t"),
    file = file,
    fileBasename = vim.fn.fnamemodify(file, ":t"),
    fileBasenameNoExtension = vim.fn.fnamemodify(file, ":t:r"),
    fileDirname = vim.fn.fnamemodify(file, ":h"),
    fileExtname = file ~= "" and ("." .. vim.fn.fnamemodify(file, ":e")) or "",
    relativeFile = file ~= "" and vim.fn.fnamemodify(file, ":.") or "",
    relativeFileDirname = file ~= "" and vim.fn.fnamemodify(vim.fn.fnamemodify(file, ":."), ":h") or "",
  }
end

---展开字符串中的模板变量
---支持：
---1. ${workspaceFolder} 这类普通变量
---2. ${env:HOME} 这类环境变量
---@param value any 要展开的值，非字符串会原样返回
---@param config table|nil dap 配置
---@param extra_context table<string, string>|nil 额外上下文，可覆盖默认值
---@return any
function M.expand(value, config, extra_context)
  if type(value) ~= "string" then
    return value
  end

  local context = build_context(config)

  if extra_context then
    context = vim.tbl_extend("force", context, extra_context)
  end

  -- 先处理 ${env:XXX}
  value = value:gsub("%${env:([%w_]+)}", function(name)
    return os.getenv(name) or ""
  end)

  -- 再处理普通变量 ${xxx}
  value = value:gsub("%${([%w_]+)}", function(name)
    return context[name] or ("${" .. name .. "}")
  end)

  return value
end

---递归展开 table 中的所有字符串
---@param obj any
---@param config table|nil
---@param extra_context table<string, string>|nil
---@return any
function M.expand_deep(obj, config, extra_context)
  if type(obj) == "string" then
    return M.expand(obj, config, extra_context)
  end

  if type(obj) ~= "table" then
    return obj
  end

  local result = {}
  for k, v in pairs(obj) do
    result[k] = M.expand_deep(v, config, extra_context)
  end
  return result
end

return M
