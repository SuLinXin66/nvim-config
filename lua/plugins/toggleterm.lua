return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true,

    opts = function()
      -- ------------------------------
      -- Helpers: ONE source of truth
      -- Terminal.display_name === TermSelect label
      -- winbar shows the same label (except float -> disabled)
      -- ------------------------------

      local function get_term_from_current_buf()
        local n = vim.b.toggle_number
        if not n then
          return nil
        end
        local ok, term = pcall(require("toggleterm.terminal").get, n)
        return ok and term or nil
      end

      local function set_term_label(term, label)
        if not term or not label or label == "" then
          return
        end

        term.display_name = label
        vim.b.term_label = label

        -- if current window is this terminal, refresh immediately
        if vim.bo.buftype == "terminal" then
          if term.direction == "float" then
            vim.wo.winbar = ""
          else
            vim.wo.winbar = " " .. label .. " "
          end
        end
      end

      local function ensure_default_label(term)
        if not term then
          return
        end
        if term.display_name and term.display_name ~= "" then
          return
        end

        -- default label: Shell #<n>
        local n = term.id or vim.b.toggle_number
        local label = n and ("Shell #" .. n) or "Shell"
        set_term_label(term, label)
      end

      local function refresh_current_winbar(term)
        if vim.bo.buftype ~= "terminal" then
          return
        end
        local name = vim.api.nvim_buf_get_name(0)
        if not name:find("toggleterm#") then
          return
        end

        local t = term or get_term_from_current_buf()
        if t then
          ensure_default_label(t)
        end

        local label = (t and t.display_name) or vim.b.term_label or "Terminal"
        vim.b.term_label = label

        -- ✅ float: disable winbar (float already has title)
        if t and t.direction == "float" then
          vim.wo.winbar = ""
          return
        end

        vim.wo.winbar = " " .. label .. " "
      end

      -- expose helpers for init() commands/autocmd
      vim.g.__toggleterm_helpers = {
        get_term = get_term_from_current_buf,
        set_label = set_term_label,
        refresh_winbar = refresh_current_winbar,
        ensure_default_label = ensure_default_label,
      }

      return {
        open_mapping = false,
        start_in_insert = true,
        insert_mappings = true,
        persist_mode = true,
        close_on_exit = true,
        shade_terminals = true,

        float_opts = {
          border = "rounded",
          winblend = 0,
        },

        direction = "horizontal",
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return math.floor(vim.o.columns * 0.35)
          end
        end,

        -- hook: terminal first created
        on_create = function(term)
          ensure_default_label(term) -- make TermSelect readable immediately
        end,

        -- hook: terminal window opened
        on_open = function(term)
          -- window tweaks
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
          vim.opt_local.foldcolumn = "0"

          vim.schedule(function()
            refresh_current_winbar(term) -- float will auto-clear winbar
          end)
        end,
      }
    end,

    keys = {
      -- ✅ Scratch float (always has title from the first open)
      { "<C-\\>", "<cmd>ToggleTermScratch<cr>", mode = "n", desc = "Terminal: Scratch (float)" },

      -- hide terminal (terminal-mode)
      { "<C-q>", "<cmd>ToggleTerm<cr>", mode = "t", desc = "Terminal: Hide" },

      -- numbered terminals
      { "<leader>t1", "<cmd>1ToggleTerm<cr>", desc = "Terminal: #1" },
      { "<leader>t2", "<cmd>2ToggleTerm<cr>", desc = "Terminal: #2" },
      { "<leader>t3", "<cmd>3ToggleTerm<cr>", desc = "Terminal: #3" },
      { "<leader>t4", "<cmd>4ToggleTerm<cr>", desc = "Terminal: #4" },

      -- direction helpers
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal: Bottom" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal: Right" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal: Float" },
      { "<leader>tt", "<cmd>ToggleTerm direction=tab<cr>", desc = "Terminal: Tab" },

      -- git
      { "<leader>tg", "<cmd>ToggleTermGit<cr>", desc = "Terminal: Git (lazygit)" },

      -- rename
      { "<leader>tR", "<cmd>TermRenamePrompt<cr>", desc = "Terminal: Rename" },

      -- new/select
      { "<leader>tn", "<cmd>TermNew<cr>", desc = "Terminal: New" },
      { "<leader>tS", "<cmd>TermSelect<cr>", desc = "Terminal: Select" },
    },

    init = function()
      -- fallback: keep winbar consistent when re-entering windows
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        callback = function()
          if vim.bo.buftype ~= "terminal" then
            return
          end
          local name = vim.api.nvim_buf_get_name(0)
          if not name:find("toggleterm#") then
            return
          end
          local h = vim.g.__toggleterm_helpers
          if not h then
            return
          end
          vim.schedule(function()
            h.refresh_winbar()
          end)
        end,
      })

      -- Rename: update BOTH winbar and TermSelect label (display_name)
      vim.api.nvim_create_user_command("TermRename", function(opts)
        local label = table.concat(opts.fargs, " ")
        if not label or label == "" then
          return
        end
        local h = vim.g.__toggleterm_helpers
        if not h then
          return
        end
        local term = h.get_term()
        if term then
          h.set_label(term, label)
          h.refresh_winbar(term)
        end
      end, { nargs = "+" })

      vim.api.nvim_create_user_command("TermRenamePrompt", function()
        vim.ui.input({ prompt = "Rename terminal: " }, function(input)
          if input and input ~= "" then
            vim.cmd("TermRename " .. input)
          end
        end)
      end, {})

      -- Git terminal (lazygit)
      local git_term
      vim.api.nvim_create_user_command("ToggleTermGit", function()
        local Terminal = require("toggleterm.terminal").Terminal
        if not git_term then
          local has_lazygit = vim.fn.executable("lazygit") == 1
          git_term = Terminal:new({
            cmd = has_lazygit and "lazygit" or nil,
            direction = "float",
            hidden = true,
            dir = "git_dir",
            close_on_exit = true,
            display_name = "Git",
          })
        end
        git_term:toggle()

        local h = vim.g.__toggleterm_helpers
        if h then
          vim.schedule(function()
            h.refresh_winbar(git_term) -- float -> clears winbar
          end)
        end
      end, {})

      -- Scratch float terminal (first open has title)
      local scratch_term
      vim.api.nvim_create_user_command("ToggleTermScratch", function()
        local Terminal = require("toggleterm.terminal").Terminal
        if not scratch_term then
          scratch_term = Terminal:new({
            direction = "float",
            hidden = true,
            close_on_exit = true,
            display_name = "Scratch", -- 你想改名字就在这里改
          })
        end
        scratch_term:toggle()

        local h = vim.g.__toggleterm_helpers
        if h then
          vim.schedule(function()
            h.refresh_winbar(scratch_term) -- float -> clears winbar
          end)
        end
      end, {})
    end,
  },
}
