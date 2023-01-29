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
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["aF"] = "@block.outer",
        ["iF"] = "@block.inner",
      },
    },
  },
})
