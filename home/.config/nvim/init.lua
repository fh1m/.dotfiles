-- Sensei: the editor is an instrument, not another background service.
vim.g.mapleader = ' '
vim.g.maplocalleader = ','
require('sensei.options')
local lazy = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazy) then
  local result = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazy })
  if vim.v.shell_error ~= 0 then error('Could not install lazy.nvim: ' .. result) end
end
vim.opt.rtp:prepend(lazy)
require('lazy').setup({ { import = 'sensei.plugins' } }, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  checker = { enabled = false }, change_detection = { enabled = false },
  install = { colorscheme = { 'sensei' } },
  ui = { border = 'single' },
  performance = { rtp = { disabled_plugins = { 'netrwPlugin', 'matchit' } } },
})
require('sensei.keys')
require('sensei.environment').setup()
