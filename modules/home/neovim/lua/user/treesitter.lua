-- Enable treesitter highlighting for all buffers that have a parser
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      -- Enable indentation via treesitter
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Textobjects (requires nvim-treesitter-textobjects plugin)
require("nvim-treesitter-textobjects").setup({
  move = { set_jumps = true },
})

local select_to = require("nvim-treesitter-textobjects.select").select_textobject
local move = require("nvim-treesitter-textobjects.move")

-- Select
vim.keymap.set({ "x", "o" }, "af", function() select_to("@function.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "if", function() select_to("@function.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "aF", function() select_to("@block.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "iF", function() select_to("@block.inner", "textobjects") end)

-- Move
vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_previous_start("@function.outer", "textobjects") end)
