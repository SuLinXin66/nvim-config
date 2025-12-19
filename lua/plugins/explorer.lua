return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        -- 1. 完美适配你的窗口习惯
        win = {
          explorer = {
            width = 40, -- 保持你习惯的 40 宽度
          },
        },
        -- 2. 迁移你的快捷键习惯
        mappings = {
          -- 默认回车是打开，这里增加 'o' 习惯
          ["o"] = "confirm",
          -- 窗口分割习惯
          ["v"] = "edit_vsplit",
          ["h"] = "edit_split",
          -- 过滤与显示习惯 (对应你原先的 i 和 .)
          ["i"] = "toggle_custom",  -- 切换自定义过滤
          ["."] = "toggle_hidden",  -- 切换隐藏文件/点文件
          -- 其它操作
          ["r"] = "rename",
          ["a"] = "add",
          ["d"] = "delete",
          ["c"] = "copy",
          ["p"] = "paste",
          ["x"] = "cut",
          ["<F5>"] = "refresh",
        },
      },
    },
    keys = {
      -- 3. 找回你最习惯的启动按键
      { "<A-m>", function() Snacks.explorer() end, desc = "打开侧边栏 (Explorer)" },
    },
  },
}