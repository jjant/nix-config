require('user.options')
require('user.treesitter')
require('user.keymap')
require('user.harpoon')
require('user.telescope')
require('user.lsp')
require('user.quickscope')
require('user.smithy')

require('marks').setup()
require('gitsigns').setup()
require('nvim-autopairs').setup()
require('nvim-web-devicons').setup()
require('lualine').setup()
require('nvim-surround').setup()

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
