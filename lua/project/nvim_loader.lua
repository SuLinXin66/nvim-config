local M = {}

local STATE = {
  loaded = false,
  project_root = nil,
  nvim_dir = nil,
  registry = {},
}

-- debug 开关（默认 false）
vim.g.project_nvim_debug = vim.g.project_nvim_debug or false

local function log(msg)
  if vim.g.project_nvim_debug then
    print("[project.nvim] " .. msg)
  end
end

local function warn(msg)
  vim.notify("[project.nvim] " .. msg, vim.log.levels.WARN)
end

local function is_real_file_buf(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function find_nvim_dir(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = vim.fs.dirname(file)
  local found = vim.fs.find(".nvim", { path = dir, upward = true, type = "directory" })
  return found[1]
end

local function load_file(path)
  log("loading " .. path)
  local ok, err = pcall(dofile, path)
  if not ok then
    warn(err)
  end
end

-- 关键：清掉“当前项目”的 dap.configurations 里的旧项（否则 UI 会残留）
local function purge_project_dap(project_root)
  if not project_root or project_root == "" then
    return
  end

  local ok, dap = pcall(require, "dap")
  if not ok or type(dap) ~= "table" then
    return
  end

  if type(dap.configurations) ~= "table" then
    return
  end

  for ft, list in pairs(dap.configurations) do
    if type(list) == "table" then
      local keep = {}
      for _, cfg in ipairs(list) do
        -- 只删属于当前项目的（必须是你项目里打过 __project_root 标记的）
        if type(cfg) ~= "table" or cfg.__project_root ~= project_root then
          table.insert(keep, cfg)
        end
      end
      dap.configurations[ft] = keep
    end
  end
end

function M.try_load_once()
  if STATE.loaded then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not is_real_file_buf(bufnr) then
    return
  end

  local nvim_dir = find_nvim_dir(bufnr)
  if not nvim_dir then
    return
  end

  STATE.nvim_dir = nvim_dir
  STATE.project_root = vim.fs.dirname(nvim_dir)
  vim.g.project_root = STATE.project_root

  local init = nvim_dir .. "/init.lua"
  local daplua = nvim_dir .. "/dap.lua"

  if vim.uv.fs_stat(init) then
    load_file(init)
  elseif vim.uv.fs_stat(daplua) then
    load_file(daplua)
  end

  STATE.loaded = true
end

function M.reload()
  -- 如果已经加载过项目：先把该项目的 dap 配置从内存里清掉
  if STATE.project_root then
    purge_project_dap(STATE.project_root)
  end

  STATE.loaded = false
  STATE.registry = {}

  -- 重新加载
  M.try_load_once()
end

function M.state()
  return STATE
end

-- Debug 开关（保持你原来的命令）
vim.api.nvim_create_user_command("ProjectDebugOn", function()
  vim.g.project_nvim_debug = true
  print("[project.nvim] debug ON")
end, {})

vim.api.nvim_create_user_command("ProjectDebugOff", function()
  vim.g.project_nvim_debug = false
  print("[project.nvim] debug OFF")
end, {})

vim.api.nvim_create_user_command("ProjectNvimReload", function()
  M.reload()
end, {})

-- 项目级 DAP 选择器（只显示当前项目的）
vim.keymap.set("n", "<leader>dL", function()
  M.try_load_once()

  if not STATE.project_root then
    warn("还没定位到项目 .nvim：先打开项目里的任意文件")
    return
  end

  local dap = require("dap")
  local items = {}

  for ft, arr in pairs(dap.configurations or {}) do
    for _, cfg in ipairs(arr) do
      if type(cfg) == "table" and cfg.__project_root == STATE.project_root then
        cfg.__project_ft = cfg.__project_ft or ft
        table.insert(items, cfg)
      end
    end
  end

  if #items == 0 then
    warn("没有项目级 DAP 配置（检查 .nvim/dap.lua 是否写入 cfg.__project_root）")
    return
  end

  vim.ui.select(items, {
    prompt = "项目调试启动器",
    format_item = function(it)
      return (it.name or "<未命名>") .. " [" .. (it.__project_ft or "?") .. "]"
    end,
  }, function(choice)
    if choice then
      local run_cfg = vim.deepcopy(choice)
      -- 去掉内部标记，避免影响适配器解析
      run_cfg.__project_root = nil
      run_cfg.__project_ft = nil
      dap.run(run_cfg)
    end
  end)
end, { desc = "DAP: 项目级启动器选择器" })

-- 自动加载（只触发一次：try_load_once 内部会拦住）
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function()
    pcall(M.try_load_once)
  end,
})

return M
