vim.opt.backup = false

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.showtabline = 2

vim.opt.swapfile = false

vim.opt.numberwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wrap = false
vim.opt.scrolloff = 8

vim.opt.termguicolors = true
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.g.mapleader = " "

-- This is shown in lualine already
vim.opt.showmode = false

vim.opt.showcmd = true

-- Always show status line
vim.opt.laststatus = 2

-- Always enable mouse
vim.opt.mouse = 'a'
-- Allow 1000 undos
vim.opt.undolevels = 1000
-- Command history has 1000 slots
vim.opt.history = 1000

vim.opt.cursorline = true -- Highlight the line that the cursor is on

-- Automatically use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.smarttab = true
