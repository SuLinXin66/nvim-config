local logger = require("tools.logger")

local M = {}

---获取项目根目录，优先使用 LazyVim.root()，回退到 uv.cwd / vim.fn.getcwd
---@return string
function M.root()
  local ok, ret = pcall(function()
    return LazyVim.root()
  end)

  if ok and ret and ret ~= "" then
    return ret
  end

  local uv = vim.uv or vim.loop
  local cwd = uv and uv.cwd() or nil
  return cwd or vim.fn.getcwd()
end

---检查命令是否可用，不可用时自动发出警告
---@param cmd string
---@return boolean
function M.executable(cmd)
  if vim.fn.executable(cmd) == 1 then
    return true
  end

  logger.warn("未找到命令：" .. cmd, "runtime")
  return false
end

---获取当前 shell 路径
---@return string
function M.get_shell()
  if vim.o.shell and vim.o.shell ~= "" then
    return vim.o.shell
  end
  return "/bin/sh"
end

---将命令包装为 login shell 执行，确保能读取到用户环境变量
---@param cmd string
---@return string[]
function M.shell_cmd(cmd)
  return { M.get_shell(), "-lc", cmd }
end

return M
