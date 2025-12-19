local status, dashboard = pcall(require, "dashboard")
if not status then
  vim.notify("没有找到 dashboard")
  return
end

dashboard.setup({
  theme = 'doom', -- 推荐使用 doom 主题，它支持你之前的这种中间列表布局
  config = {
    -- 1. 对应旧版的 custom_header
    header = {
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[]],
      [[          ▀████▀▄▄               ▄█ ]],
      [[            █▀    ▀▀▄▄▄▄▄     ▄▄▀▀█ ]],
      [[      ▄        █           ▀▀▀▀▄  ▄▀  ]],
      [[     ▄▀ ▀▄      ▀▄               ▀▄▀  ]],
      [[    ▄▀    █      █▀    ▄█▀▄      ▄█    ]],
      [[    ▀▄     ▀▄  █      ▀██▀      ██▄█   ]],
      [[     ▀▄    ▄▀ █    ▄██▄   ▄  ▄  ▀▀ █  ]],
      [[      █  ▄▀  █     ▀██▀    ▀▀ ▀▀  ▄▀  ]],
      [[     █   █  █       ▄▄            ▄▀   ]],
      [[]],
      [[]],
      [[]],
    },
    
    -- 2. 对应旧版的 custom_center
    center = {
      {
        icon = "  ",
        desc = "Projects                           ",
        action = "Telescope projects",
        key = "p", -- 新版建议绑定快捷键
      },
      {
        icon = "  ",
        desc = "Recently files                     ",
        action = "Telescope oldfiles",
        key = "r",
      },
      {
        icon = "󰌌  ",
        desc = "Edit keybindings                   ",
        action = "edit ~/.config/nvim/lua/keybindings.lua",
        key = "k",
      },
      {
        icon = "󰈞  ",
        desc = "Find file                          ",
        action = "Telescope find_files",
        key = "f",
      },
      {
        icon = "󰏘  ",
        desc = "Change Theme                       ",
        action = "Telescope colorscheme",
        key = "t",
      },
      {
        icon = "  ",
        desc = "Edit Projects                      ",
        action = "edit ~/.local/share/nvim/project_nvim/project_history",
        key = "e",
      },
    },

    -- 3. 对应旧版的 custom_footer
    footer = {
      "",
      "",
      "https://github.com/nshen/learn-neovim-lua",
    },
  },
})
