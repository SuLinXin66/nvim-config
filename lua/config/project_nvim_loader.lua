-- 项目 .nvim 自动加载器（会话内只加载一次）
-- 关键特性：
-- 1) 自动加载项目 .nvim 下所有 *.lua（init.lua 优先，其它按字母排序）
-- 2) 项目脚本对 dap.configurations 的新增：只给 <leader>dL 使用
-- 3) 加载后还原 dap.configurations，保证 <leader>dc 仍是默认行为
-- 4) 日志强制写入 :messages（用 nvim_echo），开启开关后一定能看到

local M = {}

local STATE = {
  loaded = false,
  project_root = nil,
  nvim_dir = nil,
  registry = {},
}

-- 默认关闭；你可以改成 true 或 :ProjectNvimDebugOn
vim.g.project_nvim_debug = vim.g.project_nvim_debug or true

local function echo(hl, msg)
  vim.api.nvim_echo({ { "[project.nvim] " .. msg, hl } }, true, {})
end

local function log(msg)
  if vim.g.project_nvim_debug then
    echo("Comment", msg)
  end
end

local function log_warn(msg)
  if vim.g.project_nvim_debug then
    echo("WarningMsg", msg)
  end
end

local function log_err(msg)
  echo("ErrorMsg", msg)
end

local function is_real_file_buf(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if not name or name == "" then
    return false
  end
  return true
end

local function find_nvim_dir_from_buf(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file or file == "" then
    return nil
  end
  local dir = vim.fs.dirname(file)
  if not dir then
    return nil
  end
  local found = vim.fs.find(".nvim", { path = dir, upward = true, type = "directory", limit = 1 })
  return found[1]
end

local function load_file(path)
  log("loading: " .. path)
  local ok, e = pcall(dofile, path)
  if not ok then
    log_err("加载失败: " .. path .. " | " .. tostring(e))
    return false
  end
  return true
end

local function list_project_lua_files(nvim_dir)
  local files = vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { path = nvim_dir, type = "file" })

  local init, others = nil, {}
  for _, p in ipairs(files) do
    local base = vim.fs.basename(p)
    if base == "init.lua" then
      init = p
    else
      table.insert(others, p)
    end
  end
  table.sort(others)

  local ordered = {}
  if init then
    table.insert(ordered, init)
  end
  for _, p in ipairs(others) do
    table.insert(ordered, p)
  end
  return ordered
end

local function snapshot_dap_configurations()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return nil
  end
  return vim.deepcopy(dap.configurations or {})
end

local function extract_added_dap_configs(before, after)
  local added = {}
  local count = 0

  local before_len = {}
  for ft, list in pairs(before or {}) do
    if type(list) == "table" then
      before_len[ft] = #list
    end
  end

  for ft, list in pairs(after or {}) do
    if type(list) == "table" then
      local n_before = before_len[ft] or 0
      local n_after = #list
      if n_after > n_before then
        for i = n_before + 1, n_after do
          local cfg = list[i]
          if type(cfg) == "table" then
            local copy = vim.deepcopy(cfg)
            copy.__project_ft = ft
            copy.__project_root = STATE.project_root
            table.insert(added, copy)
            count = count + 1
          end
        end
      end
    end
  end

  return added, count
end

local group = vim.api.nvim_create_augroup("ProjectNvimLoader", { clear = true })

local function try_load_project_once()
  log("try_load_project_once enter")

  if STATE.loaded then
    log("already loaded, skip")
    return true
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not is_real_file_buf(bufnr) then
    log_warn("skip: current buffer is not a real file (buftype=" .. tostring(vim.bo[bufnr].buftype) .. ")")
    return false
  end

  local nvim_dir = find_nvim_dir_from_buf(bufnr)
  if not nvim_dir then
    log_warn("skip: no .nvim found upward from current file")
    return false
  end

  STATE.nvim_dir = nvim_dir
  STATE.project_root = vim.fs.dirname(nvim_dir)
  STATE.loaded = true

  log("found .nvim: " .. STATE.nvim_dir)
  log("project_root: " .. STATE.project_root)

  vim.g.project_root = STATE.project_root
  vim.g.project_nvim_dir = STATE.nvim_dir

  local ok_dap, dap = pcall(require, "dap")
  local before = nil
  if ok_dap then
    before = snapshot_dap_configurations()
    log("snapshot dap.configurations done")
  else
    log_warn("dap not available: will not collect project dap configs")
  end

  local files = list_project_lua_files(STATE.nvim_dir)
  log("will load lua files count=" .. tostring(#files))
  for _, f in ipairs(files) do
    load_file(f)
  end

  if ok_dap and before ~= nil then
    local after = snapshot_dap_configurations()
    local added, n = extract_added_dap_configs(before, after)
    STATE.registry = added
    dap.configurations = before
    log("collected project dap configs=" .. tostring(n) .. ", restored dap.configurations")
  else
    STATE.registry = {}
  end

  pcall(vim.api.nvim_clear_autocmds, { group = group })
  log("load done, autocmd cleared")
  return true
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = group,
  desc = "Load project .nvim once",
  callback = function()
    pcall(try_load_project_once)
  end,
})

vim.keymap.set("n", "<leader>dL", function()
  pcall(try_load_project_once)

  if not STATE.loaded then
    echo("WarningMsg", "项目 .nvim 还没加载：先打开项目里的任意文件")
    return
  end

  if #STATE.registry == 0 then
    echo(
      "WarningMsg",
      "没有收集到项目调试配置：请确认项目 .nvim 下脚本 append 了 dap.configurations.<ft>"
    )
    return
  end

  local ok, dap = pcall(require, "dap")
  if not ok then
    echo("ErrorMsg", "dap 未安装或未加载")
    return
  end

  vim.ui.select(STATE.registry, {
    prompt = "项目调试启动器（仅项目）",
    format_item = function(item)
      local ft = item.__project_ft and (" [" .. item.__project_ft .. "]") or ""
      return (item.name or "<未命名>") .. ft
    end,
  }, function(choice)
    if not choice then
      return
    end
    local run_cfg = vim.deepcopy(choice)
    run_cfg.__project_ft = nil
    run_cfg.__project_root = nil
    dap.run(run_cfg)
  end)
end, { desc = "DAP: 项目级启动器（仅项目）" })

local function reset_state()
  STATE.loaded = false
  STATE.registry = {}
  STATE.project_root = nil
  STATE.nvim_dir = nil
end

vim.api.nvim_create_user_command("ProjectConfigDebugOn", function()
  vim.g.project_nvim_debug = true
  echo("Comment", "debug ON (use :messages)")
end, {})

vim.api.nvim_create_user_command("ProjectConfigDebugOff", function()
  vim.g.project_nvim_debug = false
  echo("Comment", "debug OFF")
end, {})

vim.api.nvim_create_user_command("ProjectConfigReload", function()
  reset_state()
  print("[project.nvim] state resetm reloading project .nvim...")
  try_load_project_once()
end, {})

M.state = STATE
M.try_load_project_once = try_load_project_once

return M
