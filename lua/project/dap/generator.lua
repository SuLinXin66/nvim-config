local M = {}

function M.setup()
  vim.api.nvim_create_user_command("ProjectDapAdd", function()
    local root = vim.g.project_root
    if not root then
      vim.notify("未加载项目 .nvim", vim.log.levels.WARN)
      return
    end

    local path = root .. "/.nvim/dap.lua"
    vim.fn.mkdir(root .. "/.nvim", "p")

    local name = vim.fn.input("启动器名称: ")
    local bin = vim.fn.input("bin 名（可空）: ")
    local args = vim.fn.input("args（空格分隔）: ")

    local block = [[
local dap = require("dap")
local h = require("project.dap.helpers")

dap.configurations.rust = dap.configurations.rust or {}

table.insert(dap.configurations.rust, {
  name = "]] .. name .. [[",
  type = "codelldb",
  request = "launch",
  cwd = "${workspaceFolder}",
  program = h.cargo_program { ]] ..
    (bin ~= "" and ('bin = "' .. bin .. '"') or "") .. [[ },
  args = { ]] .. args .. [[ },
  __project_root = vim.g.project_root,
  __project_ft = "rust",
})
]]

    local f = io.open(path, "a")
    f:write("\n\n" .. block)
    f:close()

    vim.notify("已写入 " .. path)
  end, {})
end

return M
