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
    move = {
      enable = true,
      -- Set jumps in the jumplist
      set_jumps = true,
      goto_next_start = {
        ["[f"] = "@function.outer",
      },
      goto_previous_start = {
        ["]f"] = "@function.outer",
      },
    },
  },
})
