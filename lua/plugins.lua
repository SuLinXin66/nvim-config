local packer = require("packer")
packer.startup({function()
  -- Packer 可以管理自己本身
  use 'wbthomason/packer.nvim'
  -- 你的插件列表...
   --------------------- colorschemes --------------------
    -- tokyonight
    use("folke/tokyonight.nvim")
    -- OceanicNext
    use("mhartington/oceanic-next")
    -- gruvbox
    use({ "ellisonleao/gruvbox.nvim", requires = { "rktjmp/lush.nvim" } })
    -- zephyr 暂时不推荐，详见上边解释
    -- use("glepnir/zephyr-nvim")
    -- nord
    use("shaunsingh/nord.nvim")
    -- onedark
    use("ful1e5/onedark.nvim")
    -- nightfox
    use("EdenEast/nightfox.nvim")
    -------------------------------------------------------
    -------------------------- plugins -------------------------------------------
    -- nvim-tree
    use({ "kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons" })
    -- bufferline
    use({ "akinsho/bufferline.nvim", requires = { "kyazdani42/nvim-web-devicons", "moll/vim-bbye" }})
    -- lualine
    use({ "nvim-lualine/lualine.nvim", requires = { "kyazdani42/nvim-web-devicons" } })
    use("arkav/lualine-lsp-progress")
    -- telescope
    use { 'nvim-telescope/telescope.nvim', requires = { "nvim-lua/plenary.nvim" } }
    -- telescope extensions
    use "LinArcX/telescope-env.nvim"
    -- dashboard-nvim
    use({"glepnir/dashboard-nvim", requires = { "nvim-tree/nvim-web-devicons" }})
    -- project
    use("ahmedkhalf/project.nvim")
    -- treesitter
    --use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
    use({
      "nvim-treesitter/nvim-treesitter",
      -- 方式 A：锁定到特定的标签（推荐）
      tag = "v0.9.2", 
      -- 或者方式 B：锁定到明确存在的兼容哈希
      -- commit = "610656e", 
      run = ":TSUpdate",
    })

end,
config = {
  display = {
    open_fn = require('packer.util').float,
  }
}})

-- 下边代码中我列出了目前常见的几个代理站点，供你尝试，但还是推荐使用 Github， 因为代理站点有些冷门的插件有可能没有同步，或者同步不及时，也有可能有并发数限制等，体验并不是很好。
-- packer.startup({
--   function(use)
--     -- Packer 可以管理自己本身
--     use 'wbthomason/packer.nvim'
--     -- 你的插件列表...
--   end,
--   config = {
--     -- 并发数限制
--     max_jobs = 16,
--     -- 自定义源
--     git = {
--       -- default_url_format = "https://hub.fastgit.xyz/%s",
--       -- default_url_format = "https://mirror.ghproxy.com/https://github.com/%s",
--       -- default_url_format = "https://gitcode.net/mirrors/%s",
--       -- default_url_format = "https://gitclone.com/github.com/%s",
--     },
--   },
-- })

-- 每次保存 plugins.lua 自动安装插件
pcall(
  vim.cmd,
  [[
    augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup end
  ]]
)

