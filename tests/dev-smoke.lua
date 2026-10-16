-- Run with a small disposable Python fixture; never write a user's project.
local function run()
  assert(vim.g.colors_name == 'sensei', 'theme missing')
  assert(vim.fn.exists(':DevInfo') == 2, 'environment commands missing')
  assert(vim.fn.exists(':Tutor') == 2, 'native tutor unavailable')
  local names = { 'mini.nvim', 'blink.cmp', 'which-key.nvim', 'fzf-lua', 'lualine.nvim', 'nvim-treesitter-textobjects',
    'overseer.nvim', 'nvim-dap', 'neotest', 'aerial.nvim', 'octo.nvim', 'render-markdown.nvim',
    'conform.nvim', 'trouble.nvim', 'grug-far.nvim', 'diffview.nvim', 'neogen' }
  require('lazy').load({ plugins = names })
  assert(type(require('mini.move').move_selection)=='function', 'Selection movement missing')
  assert(type(require('mini.splitjoin').toggle)=='function', 'Split/join missing')
  assert(type(require('mini.hipatterns').gen_highlighter.hex_color)=='function', 'Color preview missing')
  assert(vim.fn.executable('ruff') == 1, 'Ruff unavailable')
  assert(vim.fn.executable('basedpyright-langserver') == 1, 'Python type server unavailable')
  assert(require('luasnip').get_snippets('python'), 'snippets not loaded')
  local parser = vim.treesitter.get_parser(0, 'python')
  assert(parser:parse()[1], 'Python parser not working')
  assert(require('conform').list_formatters(0)[1], 'Python formatter missing')
  assert(require('dap').adapters.python, 'Python debugger unavailable')
  assert(require('dap').adapters.codelldb, 'C/C++ debugger unavailable')
  assert(vim.wait(20000, function()
    local ready = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.initialized then ready[c.name] = true end end
    return ready.basedpyright and ready.ruff
  end, 100), 'Python language servers did not initialize')
  local py = vim.lsp.get_clients({ name = 'basedpyright' })[1]
  local response = py:request_sync('textDocument/hover', {
    textDocument = { uri = vim.uri_from_bufnr(0) }, position = { line = 1, character = 5 } }, 10000, 0)
  assert(response and not response.err, 'Hover request failed')
  -- Clipboard music shortcut must remain untouched.
  assert(vim.fn.maparg('<C-Space>', 'i') == '', 'Global music shortcut intercepted')
  assert(require('blink.cmp.config').keymap['<CR>'] == nil, 'Enter unexpectedly accepts completion')
  print('PASS: theme, tutor, lazy features, snippets, parser, formatter, DAP, two Python LSPs, hover, key ownership')
  vim.cmd('qa!')
end
local ok, err = xpcall(run, debug.traceback)
if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit') end
