-- Hide search results by pressing Esc on normal mode
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>")

-- Keep selection while indenting
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
