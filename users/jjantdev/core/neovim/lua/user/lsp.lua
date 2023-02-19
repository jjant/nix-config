local lsp = require('lsp-zero')
local rust_tools = require("rust-tools")

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

lsp.setup_servers({ 'rnix', 'sumneko_lua', 'bashls' })
lsp.nvim_workspace()
lsp.setup()

local format_augroup = vim.api.nvim_create_augroup('LspFormat', { clear = true })

local create_format_autocmd = function(client)
  vim.api.nvim_clear_autocmds({ group = format_augroup })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = format_augroup,
    callback = function()
      vim.lsp.buf.format({ async = false })
    end,
    desc = 'Autoformat code (' .. client.name .. ')'
  })
end

local common_on_attach = function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, opts)

  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

  vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_next, opts)

  vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, opts)

  vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, opts)

  create_format_autocmd(client)
end

lsp.on_attach(common_on_attach)

rust_tools.setup({
  server = { on_attach = function(client, bufnr)
    rust_tools.inlay_hints.enable()

    common_on_attach(client, bufnr)

    local opts = { buffer = bufnr, remap = false }
    local open_cargo_toml = rust_tools.open_cargo_toml.open_cargo_toml
    vim.keymap.set('n', '<Leader>gc', open_cargo_toml, opts)
  end }
})
