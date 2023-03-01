local smithy_augroup = vim.api.nvim_create_augroup("SmithyAugroup", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = smithy_augroup,
  pattern = "*.smithy",
  desc = "Set filetype for `*.smithy` files",
  callback = function()
    vim.bo.filetype = "smithy"
  end
})
