local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', telescope_builtin.git_files)
vim.keymap.set('n', '<C-g>', telescope_builtin.live_grep)
vim.keymap.set('n', '<Leader>fh', telescope_builtin.help_tags)
