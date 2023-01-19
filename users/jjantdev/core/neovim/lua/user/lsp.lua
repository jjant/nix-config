local lsp = require('lsp-zero')

lsp.preset('recommended')
lsp.nvim_workspace()
lsp.setup()

local format_augroup = vim.api.nvim_create_augroup('LspFormat', { clear = true })

function create_format_autocmd()
  vim.api.nvim_clear_autocmds({ group = format_augroup })
  vim.api.nvim_create_autocmd('BufWritePre', { callback = function()
    vim.lsp.buf.format({ async = false })
  end, desc = 'Autoformat code' })
end

lsp.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

  create_format_autocmd()
end)
