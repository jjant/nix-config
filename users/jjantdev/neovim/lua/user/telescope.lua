local telescope = require('telescope')

telescope.setup({
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case',
    },
  },
})
telescope.load_extension('fzf')

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', telescope_builtin.git_files)
vim.keymap.set('n', '<C-g>', telescope_builtin.live_grep)

vim.keymap.set('n', '<Leader>fh', telescope_builtin.help_tags)

vim.keymap.set('n', '<Leader>ff', telescope_builtin.find_files)
