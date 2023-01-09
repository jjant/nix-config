local harpoon_mark = require('harpoon.mark')
local harpoon_ui = require('harpoon.ui')

vim.keymap.set("n", "<C-y>", harpoon_mark.add_file)
vim.keymap.set("n", "<C-e>", harpoon_ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() harpoon_ui.nav_file(1) end, { desc = "Go to harpoon file 1" })
vim.keymap.set("n", "<C-j>", function() harpoon_ui.nav_file(2) end, { desc = "Go to harpoon file 2" })
vim.keymap.set("n", "<C-k>", function() harpoon_ui.nav_file(3) end, { desc = "Go to harpoon file 3" })
vim.keymap.set("n", "<C-l>", function() harpoon_ui.nav_file(4) end, { desc = "Go to harpoon file 4" })
