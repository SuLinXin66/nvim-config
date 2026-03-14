local has_started_once = false

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F5>",
        function()
          local dap = require("dap")

          -- 1. 如果当前已经有活动调试会话
          if dap.session() then
            dap.continue()
            return
          end

          -- 2. 当前没有活动调试会话
          -- 如果之前已经启动过一次，就直接 Run Last
          if has_started_once then
            dap.run_last()
            return
          end

          -- 3. 第一次启动，没有 last，就走 Continue
          -- Continue 在无 session 时会按当前 filetype 配置启动调试
          dap.continue()
          has_started_once = true
        end,
        desc = "DAP Run Last",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "DAP Step Out",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "DAP Step Into",
      },
    },
  },
}
