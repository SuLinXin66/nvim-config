return {
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
}
