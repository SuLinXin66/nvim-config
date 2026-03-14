return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", false },
      { "<leader>dB", false },
      { "<leader>dA", false },
    },
  },
  {
    "Weissle/persistent-breakpoints.nvim",
    event = "BufReadPost",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    opts = {
      -- 官方推荐
      load_breakpoints_event = { "BufReadPost" },

      -- 默认是 stdpath('data') .. '/nvim_checkpoints'
      -- 你也可以改成 state，更像运行态数据
      save_dir = vim.fn.stdpath("state") .. "/nvim_checkpoints",

      -- 如果你有 session / project 恢复类场景，建议打开
      always_reload = true,

      perf_record = false,
    },
    config = function(_, opts)
      require("persistent-breakpoints").setup(opts)
    end,
    keys = {
      {
        "<leader>db",
        function()
          require("persistent-breakpoints.api").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("persistent-breakpoints.api").set_conditional_breakpoint()
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>dA",
        function()
          require("persistent-breakpoints.api").clear_all_breakpoints()
        end,
        desc = "Clear All Breakpoints",
      },
      {
        "<leader>dL",
        function()
          require("persistent-breakpoints.api").set_log_point()
        end,
        desc = "Log Point",
      },
    },
  },
}
