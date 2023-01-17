local rust_tools = require("rust-tools")

rust_tools.setup({
  server = {
    on_attach = function(_, bufnr)
      rust_tools.inlay_hints.enable()

      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "K", vim.lsp.buf.hover)
    end
  }
})
