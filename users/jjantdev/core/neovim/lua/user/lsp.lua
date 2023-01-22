local lsp = require('lsp-zero')

lsp.preset('system-lsp')

-- Fix Undefined global 'vim'
lsp.configure('sumneko_lua', {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

lsp.setup_servers({ 'rnix', 'sumneko_lua' })
lsp.nvim_workspace()
lsp.setup()

local format_augroup = vim.api.nvim_create_augroup('LspFormat', { clear = true })

local create_format_autocmd = function()
  vim.api.nvim_clear_autocmds({ group = format_augroup })
  vim.api.nvim_create_autocmd('BufWritePre', { callback = function()
    vim.lsp.buf.format({ async = false })
  end, desc = 'Autoformat code' })
end

lsp.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

  vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_next, opts)

  create_format_autocmd()
end)
