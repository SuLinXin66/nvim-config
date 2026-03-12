return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      win = {
        input = {
          keys = {
            ["<C-w>p"] = { "focus_preview", mode = { "n", "i" } },
          },
        },
      },
    },
  },
}
