-- Hide search results by pressing Esc on normal mode
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>")

-- Keep selection while indenting
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")

-- Delete without yanking
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")
