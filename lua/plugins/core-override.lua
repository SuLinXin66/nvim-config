local logger = require("tools.logger")
local template_expand = require("tools.template_expand")
local io_utils = require("tools.io")
local table_utils = require("tools.table")
local dap_utils = require("tools.dap")

local function save_last_run_config(config)
  local ok, err = dap_utils.write_last_run_config(config)
  if not ok then
    logger.warn("Failed to save last run config: " .. err, "dap config")
  end
  return config
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<C-w>l"] = { "focus_preview", mode = { "n", "i" } },
              ["<C-l>"] = { "focus_preview", mode = { "n", "i" } },
            },
          },
          preview = {
            keys = {
              ["<C-w>h"] = { "focus_input", mode = { "n" } },
              ["<C-h>"] = { "focus_input", mode = { "n" } },
            },
          },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      dap.listeners.on_config["vscode-launch-json-handle"] = function(config)
        config.mode = "debug"
        config.outputMode = config.outputMode or "remote"
        if config.envFile then
          local env_file_path = template_expand.expand(config.envFile)
          local env_table, err = io_utils.read_env_file_to_table(env_file_path)
          if err ~= nil then
            logger.warn("Failed to read envFile: " .. err, "dap config")
            return save_last_run_config(config)
          end
          config.env = config.env or {}
          table_utils.merge(config.env, env_table)
        end
        return save_last_run_config(config)
      end
    end,
  },
}
