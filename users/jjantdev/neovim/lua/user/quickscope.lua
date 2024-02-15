local quickscope_augroup = vim.api.nvim_create_augroup("QuickScopeAuGroup", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = quickscope_augroup,
  callback = function()
    vim.api.nvim_set_hl(0, "QuickScopePrimary", { fg = "#ff6d33", undercurl = true })
    vim.api.nvim_set_hl(0, "QuickScopeSecondary", { fg = "#06a77d", undercurl = true })
  end
})
