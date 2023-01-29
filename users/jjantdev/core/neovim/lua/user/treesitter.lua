-- Treesitter configuration
-- Parsers must be installed manually via :TSInstall
require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
  },
  playground = {
    enable = true,
    updatetime = 10,
  },
  textobjects = {
    select = {
      enable = true,
    },
  },
})
