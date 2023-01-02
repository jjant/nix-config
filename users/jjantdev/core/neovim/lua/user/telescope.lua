local telescope_builtin = require('telescope.builtin')

vim.keymap.set("n", "<C-p>", telescope_builtin.git_files)
