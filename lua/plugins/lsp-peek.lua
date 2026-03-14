return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "folke/which-key.nvim",
      opts = function(_, opts)
        opts.spec = opts.spec or {}
        table.insert(opts.spec, { "gp", group = "peek", mode = "n" })
      end,
    },
  },
  keys = {
    { "gp", desc = "+peek" },
    {
      "gpf",
      function()
        require("tools.lsp_float_full").open_target_buffer_float("textDocument/definition")
      end,
      desc = "Peek Definition File",
    },
    {
      "gpF",
      function()
        require("tools.lsp_float_full").open_target_buffer_float("textDocument/typeDefinition")
      end,
      desc = "Peek Type Definition File",
    },
  },
}
