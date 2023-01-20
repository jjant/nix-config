require('user.options')
require('user.lsp')
require('user.lsp.rust')
require('user.treesitter')
require('user.keymap')
require('user.harpoon')
require('user.telescope')

require('marks').setup()
require('gitsigns').setup()

vim.cmd.colorscheme('darkplus')

local highlight_yanked = function(args)
  local timeout = args.timeout
  local yank_group = vim.api.nvim_create_augroup('YankAugroup', { clear = true })

  vim.api.nvim_create_autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
      vim.highlight.on_yank({
        higroup = 'IncSearch',
        timeout = timeout,
      })
    end,
  })
end

highlight_yanked({ timeout = 125 })
