-- Hide search results by pressing Esc on normal mode
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR><Esc>')

-- Keep selection while indenting
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', '<', '<gv')

-- Delete without yanking
vim.keymap.set('n', '<Leader>d', '\'_d')
vim.keymap.set('v', '<Leader>d', '\'_d')

vim.keymap.set('n', '<Leader><Leader>', '<C-^>')

vim.keymap.set('n', '<Leader>x', '<Cmd>!chmod +x %<CR>', { silent = true })

-- Use ' to go to line and column with a mark,
-- intead of just to the line
vim.keymap.set('n', "'", '`')

vim.keymap.set('n', '<Leader>pv', '<Cmd>Ex<CR>')
