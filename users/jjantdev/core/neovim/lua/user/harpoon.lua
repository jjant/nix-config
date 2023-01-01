local harpoon_mark = require('harpoon.mark')
local harpoon_ui = require('harpoon.ui')

vim.keymap.set("n", "<C-y>", harpoon_mark.add_file)
vim.keymap.set("n", "<C-e>", harpoon_ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() harpoon_ui.nav_file(1) end)
vim.keymap.set("n", "<C-j>", function() harpoon_ui.nav_file(2) end)
vim.keymap.set("n", "<C-k>", function() harpoon_ui.nav_file(3) end)
vim.keymap.set("n", "<C-l>", function() harpoon_ui.nav_file(4) end)