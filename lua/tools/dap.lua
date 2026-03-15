local ioutils = require("tools.io")
local logger = require("tools.logger")
local state_last_run_cfg_filepath = ioutils.get_state_file_path("dap_last_run")

local function create_state_dir()
  if not pcall(vim.fn.mkdir, vim.fs.dirname(state_last_run_cfg_filepath), "p") then
    logger.error("Failed to create state directory for DAP last run config: " .. state_last_run_cfg_filepath)
    return false
  end
  return true
end
local M = {}

function M.read_last_run_config()
  local config, err = ioutils.read_json_to_table(state_last_run_cfg_filepath)
  if not config then
    return nil, "Failed to read last run config: " .. err
  end
  return config
end

function M.write_last_run_config(config)
  if not create_state_dir() then
    return nil, "Failed to create state directory for DAP last run config"
  end

  local ok, err, json_str
  ok, json_str = pcall(vim.fn.json_encode, config)
  if not ok then
    return nil, "Failed to encode last run config to JSON: " .. err
  end

  ok, err = pcall(vim.fn.writefile, { json_str }, state_last_run_cfg_filepath)
  if not ok then
    return nil, "Failed to write last run config: " .. err
  end
  return true
end

return M
