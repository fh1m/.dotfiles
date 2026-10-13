local o = vim.opt
o.termguicolors = true
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.cursorlineopt = 'number'
o.wrap = false
o.breakindent = true
o.scrolloff = 6
o.sidescrolloff = 8
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'
o.completeopt = 'menu,menuone,noselect'
o.updatetime = 300
o.timeoutlen = 450
o.ttimeoutlen = 30
o.mouse = 'a'
o.undofile = true
o.undolevels = 10000
o.swapfile = true
o.autoread = true
o.confirm = true
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.laststatus = 3
o.showmode = false
o.pumheight = 12
o.winborder = 'single'
o.foldmethod = 'expr'
o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldlevel = 99
o.foldlevelstart = 99
o.spelllang = 'en'
-- Python/Node language servers are standalone processes, not Nvim providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
if vim.fn.executable('wl-copy') == 1 and vim.env.WAYLAND_DISPLAY then
  o.clipboard = 'unnamedplus'
elseif vim.env.SSH_TTY or vim.env.CONTAINER_ID then
  vim.g.clipboard = {
    name = 'OSC52 copy / terminal paste',
    copy = { ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*') },
    paste = { ['+'] = function() return vim.fn.getreg('"', 1, true) end,
      ['*'] = function() return vim.fn.getreg('"', 1, true) end },
  }
end
vim.diagnostic.config({ virtual_text = false, signs = true, underline = true,
  severity_sort = true, update_in_insert = false, float = { border = 'single', source = true } })
local group = vim.api.nvim_create_augroup('SenseiCore', { clear = true })
vim.api.nvim_create_autocmd('BufReadPre', { group = group, callback = function(ev)
  local stat = vim.uv.fs_stat(ev.file)
  if stat and stat.size > 1024 * 1024 then
    vim.b[ev.buf].sensei_bigfile = true
    vim.bo[ev.buf].undofile = false
  end
end })
vim.api.nvim_create_autocmd('BufReadPost', { group = group, callback = function(ev)
  if vim.api.nvim_buf_line_count(ev.buf) > 20000 then vim.b[ev.buf].sensei_bigfile = true end
  if vim.b[ev.buf].sensei_bigfile then
    vim.bo[ev.buf].syntax = 'OFF'
    vim.bo[ev.buf].foldmethod = 'manual'
  end
end })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, { group = group, callback = function()
  -- checktime reloads clean buffers; modified buffers get Nvim's conflict prompt.
  if vim.fn.mode() ~= 'c' and vim.fn.getcmdwintype() == '' then vim.cmd('checktime') end
end })
vim.api.nvim_create_autocmd('TextYankPost', { group = group, callback = function()
  vim.hl.on_yank({ timeout = 120 })
end })
vim.filetype.add({ extension = { msg = 'rosmsg', srv = 'rosmsg', action = 'rosmsg', urdf = 'xml', xacro = 'xml' } })
