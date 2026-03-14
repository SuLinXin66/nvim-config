local M = {}

local function notify(msg, level, title)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, {
      title = title or "LazyVim",
    })
  end)
end

---普通信息
function M.info(msg, title)
  notify(msg, vim.log.levels.INFO, title)
end

---警告
function M.warn(msg, title)
  notify(msg, vim.log.levels.WARN, title)
end

---错误
function M.error(msg, title)
  notify(msg, vim.log.levels.ERROR, title)
end

---debug信息
function M.debug(msg, title)
  notify(msg, vim.log.levels.DEBUG, title)
end

---dump对象
function M.dump(obj, title, level)
  notify(vim.inspect(obj), level or vim.log.levels.INFO, title or "dump")
end

return M
