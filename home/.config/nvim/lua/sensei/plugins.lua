local function map(lhs, rhs, desc) return { lhs, rhs, desc = desc } end
return {
  { dir = vim.fn.stdpath('config'), name = 'sensei-theme', lazy = false, priority = 1000,
    config = function() vim.cmd.colorscheme('sensei') end },
  { 'nvim-mini/mini.nvim', version = false, event = 'VeryLazy', config = function()
    require('mini.ai').setup({ n_lines = 300 })
    require('mini.surround').setup({ mappings = { add = 'gsa', delete = 'gsd', replace = 'gsr',
      find = 'gsf', find_left = 'gsF', highlight = 'gsh', update_n_lines = 'gsn' } })
    require('mini.pairs').setup()
    require('mini.move').setup({ mappings = { left = '<M-S-h>', right = '<M-S-l>', down = '<M-S-j>', up = '<M-S-k>', line_left = '<M-S-h>', line_right = '<M-S-l>', line_down = '<M-S-j>', line_up = '<M-S-k>' } })
    local hipatterns = require('mini.hipatterns')
    hipatterns.setup({ highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() } })
    require('mini.splitjoin').setup({ mappings = { toggle = 'gS', split = '', join = '' } })
    require('mini.icons').setup()
    require('mini.icons').mock_nvim_web_devicons()
  end },
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = { delay = 250,
    icons = { mappings = false }, win = { border = 'single' },
    spec = { { '<leader>f', group = 'Find' }, { '<leader>c', group = 'Code' },
      { '<leader>g', group = 'Git / review' }, { '<leader>d', group = 'Debug' },
      { '<leader>t', group = 'Test' }, { '<leader>r', group = 'Run / tasks' },
      { '<leader>p', group = 'Project / environment' }, { '<leader>h', group = 'Help / learn' },
      { '<leader>a', group = 'Agent companions' }, { '<leader>w', group = 'Windows' },
      { '<leader>m', group = 'Working-file marks' }, { '<leader>x', group = 'Diagnostics' },
      { '<leader>k', group = 'Knowledge / Obsidian' } } } },
  { 'ibhagwan/fzf-lua', cmd = 'FzfLua',
    keys = { map('<leader>ff', function() require('fzf-lua').files() end, 'Files'),
      map('<leader>fg', function() require('fzf-lua').live_grep() end, 'Search text'),
      map('<leader>fb', function() require('fzf-lua').buffers() end, 'Buffers'),
      map('<leader>fr', function() require('fzf-lua').oldfiles() end, 'Recent files'),
      map('<leader>fs', function() require('fzf-lua').lsp_document_symbols() end, 'Document symbols'),
      map('<leader>fS', function() require('fzf-lua').lsp_live_workspace_symbols() end, 'Workspace symbols'),
      map('<leader>f/', function() require('fzf-lua').lgrep_curbuf() end, 'Search this buffer'),
      map('<leader>fA', function() require('fzf-lua').files({ fd_opts = '--type f --hidden --no-ignore --exclude .git' }) end, 'Files including ignored'),
      map('<leader>hk', function() require('fzf-lua').keymaps() end, 'Search keybindings'),
      map('<leader>hh', function() require('fzf-lua').helptags() end, 'Search help'),
      map('<leader>hc', function() require('fzf-lua').commands() end, 'Search commands') },
    opts = { winopts = { border = 'single', height = 0.82, width = 0.88,
      preview = { default = 'bat', layout = 'flex', horizontal = 'right:55%', vertical = 'down:45%' } },
      files = { fd_opts = '--type f --hidden --exclude .git --exclude build --exclude install --exclude log --exclude node_modules --exclude .venv --exclude datasets --exclude bags' },
      grep = { rg_opts = '--column --line-number --no-heading --color=always --smart-case --hidden -g !.git -g !build -g !install -g !log -g !node_modules -g !.venv -g !datasets -g !bags' } },
    config = function(_, opts)
      require('fzf-lua').setup(opts)
      require('fzf-lua').register_ui_select()
    end },
  { 'stevearc/oil.nvim', lazy = false, opts = { default_file_explorer = true,
    columns = { 'icon' }, view_options = { show_hidden = true },
    skip_confirm_for_simple_edits = false, watch_for_changes = false,
    float = { border = 'single' } }, keys = { map('-', '<cmd>Oil<cr>', 'Parent directory') } },
  { 'ThePrimeagen/harpoon', branch = 'harpoon2', dependencies = { 'nvim-lua/plenary.nvim' },
    keys = { map('<leader>ma', function() require('harpoon'):list():add() end, 'Pin working file'),
      map('<leader>mm', function() local h = require('harpoon'); h.ui:toggle_quick_menu(h:list()) end, 'Working files'),
      map('<leader>1', function() require('harpoon'):list():select(1) end, 'Working file 1'),
      map('<leader>2', function() require('harpoon'):list():select(2) end, 'Working file 2'),
      map('<leader>3', function() require('harpoon'):list():select(3) end, 'Working file 3'),
      map('<leader>4', function() require('harpoon'):list():select(4) end, 'Working file 4') },
    config = function() require('harpoon'):setup() end },
  { 'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false,
    config = function()
      vim.api.nvim_create_autocmd('FileType', { group = vim.api.nvim_create_augroup('SenseiTreesitter', { clear = true }),
        callback = function(ev)
          if vim.b[ev.buf].sensei_bigfile then return end
          pcall(vim.treesitter.start, ev.buf)
        end })
    end },
  { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main', event = 'VeryLazy',
    opts = { select = { lookahead = true } }, config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)
      for lhs, capture in pairs({ af = '@function.outer', ['if'] = '@function.inner', ac = '@class.outer', ic = '@class.inner', aa = '@parameter.outer', ia = '@parameter.inner' }) do
        vim.keymap.set({ 'x', 'o' }, lhs, function()
          if not vim.b.sensei_bigfile then require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects') end
        end, { desc = 'Structural textobject ' .. capture })
      end
    end },
  { 'saghen/blink.cmp', version = 'v1.10.2', event = 'InsertEnter',
    dependencies = { { 'L3MON4D3/LuaSnip', version = 'v2.*', dependencies = { 'rafamadriz/friendly-snippets' },
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
        require('luasnip.loaders.from_lua').load({ paths = vim.fn.stdpath('config') .. '/snippets' })
      end } },
    opts = { enabled = function() return not vim.b.sensei_bigfile and vim.bo.buftype ~= 'prompt' end,
      keymap = { preset = 'none', ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' }, ['<C-y>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' }, ['<C-x><C-o>'] = { 'show' },
        ['<Tab>'] = { 'snippet_forward', 'fallback' }, ['<S-Tab>'] = { 'snippet_backward', 'fallback' } },
      snippets = { preset = 'luasnip' }, signature = { enabled = true },
      completion = { list = { selection = { preselect = false, auto_insert = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
        menu = { border = 'single', draw = { columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } } } } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = { buffer = { opts = { get_bufnrs = function() return { vim.api.nvim_get_current_buf() } end } } } },
      cmdline = { enabled = false } } },
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'mason-org/mason.nvim', { 'folke/lazydev.nvim', ft = 'lua', opts = {} } },
    config = function() require('sensei.lsp').setup() end },
  { 'mason-org/mason.nvim', cmd = { 'Mason', 'MasonInstall', 'MasonLog', 'MasonUninstall' },
    opts = { PATH = 'append', ui = { border = 'single' } } },
  -- The language servers, debug adapters and formatters the config expects.
  -- Run :MasonToolsInstall on a fresh machine; nothing installs at startup.
  { 'WhoIsSethDaniel/mason-tool-installer.nvim', cmd = { 'MasonToolsInstall', 'MasonToolsUpdate' },
    dependencies = { 'mason-org/mason.nvim' },
    opts = { run_on_start = false, ensure_installed = {
      'basedpyright', 'ruff', 'clangd', 'codelldb', 'debugpy', 'lua-language-server', 'stylua',
      'typescript-language-server', 'html-lsp', 'css-lsp', 'json-lsp', 'yaml-language-server',
      'bash-language-server', 'shellcheck', 'shfmt', 'cmake-language-server', 'dockerfile-language-server',
      'lemminx', 'clang-format', 'prettier' } } },
  { 'danymat/neogen', cmd = 'Neogen', opts = { snippet_engine = 'luasnip' },
    keys = { map('<leader>cD', '<cmd>Neogen<cr>', 'Generate a structural docstring') } },
  { 'stevearc/conform.nvim', event = 'BufWritePre', cmd = 'ConformInfo',
    keys = { map('<leader>cf', function() require('conform').format({ async = true, lsp_format = 'never' }) end, 'Format explicitly') },
    config = function() require('sensei.format').setup() end },
  { 'lewis6991/gitsigns.nvim', event = { 'BufReadPost', 'BufNewFile' },
    opts = { update_debounce = 250, max_file_length = 20000, current_line_blame = false,
      on_attach = function(buf)
        local g = require('gitsigns')
        for lhs, rhs in pairs({ ['<leader>gh'] = g.preview_hunk, ['<leader>gs'] = g.stage_hunk,
          ['<leader>gu'] = g.undo_stage_hunk, ['<leader>gb'] = g.blame_line,
          [']h'] = function() g.nav_hunk('next') end, ['[h'] = function() g.nav_hunk('prev') end }) do
          vim.keymap.set('n', lhs, rhs, { buffer = buf, desc = 'Git hunk / blame' })
        end
      end } },
  { 'tpope/vim-fugitive', cmd = { 'Git', 'G', 'Gdiffsplit', 'Gread', 'Gwrite' },
    keys = { map('<leader>gg', '<cmd>Git<cr>', 'Git status') } },
  { 'sindrets/diffview.nvim', cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = { map('<leader>gd', '<cmd>DiffviewOpen<cr>', 'Review working changes'),
      map('<leader>gH', '<cmd>DiffviewFileHistory %<cr>', 'File history') }, opts = {} },
  { 'pwntester/octo.nvim', cmd = 'Octo', dependencies = { 'nvim-lua/plenary.nvim', 'ibhagwan/fzf-lua', 'nvim-tree/nvim-web-devicons' },
    opts = { picker = 'fzf-lua', enable_builtin = false },
    keys = { map('<leader>gp', '<cmd>Octo pr list<cr>', 'GitHub pull requests'),
      map('<leader>gi', '<cmd>Octo issue list<cr>', 'GitHub issues') } },
  { 'MagicDuck/grug-far.nvim', cmd = 'GrugFar', opts = { headerMaxWidth = 80 },
    keys = { map('<leader>cr', '<cmd>GrugFar<cr>', 'Find and replace with preview') } },
  { 'stevearc/aerial.nvim', cmd = { 'AerialToggle', 'AerialOpen' }, opts = { backends = { 'lsp', 'treesitter', 'markdown', 'man' },
    layout = { min_width = 24, max_width = 40 } }, keys = { map('<leader>co', '<cmd>AerialToggle<cr>', 'Code outline') } },
  { 'folke/trouble.nvim', cmd = 'Trouble', opts = {},
    keys = { map('<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', 'Diagnostics'),
      map('<leader>xq', '<cmd>Trouble qflist toggle<cr>', 'Quickfix') } },
  { 'mbbill/undotree', cmd = 'UndotreeToggle', keys = { map('<leader>cu', '<cmd>UndotreeToggle<cr>', 'Undo history') } },
  { 'stevearc/overseer.nvim', cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerInfo' },
    keys = { map('<leader>rr', '<cmd>OverseerRun<cr>', 'Run task'), map('<leader>ro', '<cmd>OverseerToggle<cr>', 'Task output') },
    config = function() require('sensei.tasks').setup() end },
  { 'mfussenegger/nvim-dap',
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio', 'mfussenegger/nvim-dap-python',
      -- Variable values drawn beside the lines they belong to, while stopped.
      { 'theHamsta/nvim-dap-virtual-text', opts = { commented = true } } },
    keys = { map('<leader>db', function() require('dap').toggle_breakpoint() end, 'Breakpoint'),
      map('<leader>dc', function() require('dap').continue() end, 'Start / continue'),
      map('<leader>dn', function() require('dap').step_over() end, 'Step over'),
      map('<leader>di', function() require('dap').step_into() end, 'Step into'),
      map('<leader>do', function() require('dap').step_out() end, 'Step out'),
      map('<leader>dt', function() require('dap').terminate() end, 'Terminate debugger'),
      map('<leader>du', function() require('dapui').toggle() end, 'Debugger panels') },
    config = function() require('sensei.debug').setup() end },
  { 'nvim-neotest/neotest', cmd = 'Neotest', dependencies = { 'nvim-neotest/nvim-nio', 'nvim-lua/plenary.nvim', 'nvim-neotest/neotest-python',
      'alfaix/neotest-gtest', 'rouge8/neotest-rust' },
    keys = { map('<leader>tn', function() require('neotest').run.run() end, 'Nearest test'),
      map('<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end, 'Test file'),
      map('<leader>ts', function() require('neotest').summary.toggle() end, 'Test summary'),
      map('<leader>to', function() require('neotest').output.open({ enter = true }) end, 'Test output'),
      map('<leader>td', function() require('neotest').run.run({ strategy = 'dap' }) end, 'Debug nearest test'),
      map('<leader>tx', function() require('neotest').run.stop() end, 'Stop tests') },
    config = function()
      require('neotest').setup({ discovery = { enabled = false }, running = { concurrent = false },
        adapters = { require('neotest-python')({ runner = 'pytest',
          python = function() return require('sensei.environment').python() end,
          dap = { justMyCode = false } }),
          require('neotest-gtest').setup({ debug_adapter = 'codelldb' }),
          require('neotest-rust')({ dap_adapter = 'codelldb' }) } })
    end },
  { 'MeanderingProgrammer/render-markdown.nvim', ft = 'markdown', opts = { enabled = true, heading = { sign = false } } },
  { 'obsidian-nvim/obsidian.nvim', version = 'v3.16.8', ft = 'markdown', cmd = 'Obsidian',
    dependencies = { 'ibhagwan/fzf-lua' },
    config = function()
      local k = require('sensei.knowledge').config()
      local workspaces = {}
      for _, v in ipairs(k.vaults or {}) do table.insert(workspaces, { name = v.name, path = v.path }) end
      if #workspaces == 0 then return end
      require('obsidian').setup({ legacy_commands = false, workspaces = workspaces,
        ui = { enable = false }, picker = { name = 'fzf-lua' }, statusline = { enabled = false },
        frontmatter = { enabled = false },
        note_id_func = function(title) return title or os.date('%Y%m%d-%H%M%S') end,
        templates = { folder = 'Templates' } })
    end,
    keys = {
      map('<leader>ks', '<cmd>Obsidian search<cr>', 'Search vault knowledge'),
      map('<leader>kq', '<cmd>Obsidian quick_switch<cr>', 'Find a note'),
      map('<leader>kw', '<cmd>Obsidian workspace<cr>', 'Switch vault freely'),
      map('<leader>kb', '<cmd>Obsidian backlinks<cr>', 'Backlinks'),
      map('<leader>kl', '<cmd>Obsidian follow_link<cr>', 'Follow knowledge link'),
      map('<leader>kn', '<cmd>Obsidian new<cr>', 'New note'),
      map('<leader>ki', '<cmd>Obsidian template<cr>', 'Insert note template') } },
  { 'nvim-lualine/lualine.nvim', event = 'VeryLazy', config = function()
    local p = { bg = '#171311', fg = '#e8e2da', dim = '#a9a29a', pink = '#f23d70' }
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
    local title = vim.api.nvim_get_hl(0, { name = 'Title', link = false })
    if normal.bg then p.bg = string.format('#%06x', normal.bg) end
    if title.fg then p.pink = string.format('#%06x', title.fg) end
    local theme = {}
    for _, mode in ipairs({ 'normal', 'insert', 'visual', 'replace', 'command' }) do
      theme[mode] = { a = { fg = p.pink, bg = p.bg, gui = 'bold' },
        b = { fg = p.fg, bg = p.bg }, c = { fg = p.dim, bg = '#090807' } }
    end
    theme.inactive = { a = { fg = '#706963', bg = '#090807' }, b = { fg = '#706963', bg = '#090807' }, c = { fg = '#706963', bg = '#090807' } }
    require('lualine').setup({ options = { theme = theme, icons_enabled = false, globalstatus = true,
      section_separators = '', component_separators = '', refresh = { statusline = 1000 } },
      sections = { lualine_a = { 'mode' }, lualine_b = { 'branch' },
        lualine_c = { { 'filename', path = 1 }, function() return require('sensei.environment').label() end,
          { 'aerial', cond = function() return package.loaded.aerial ~= nil end, sep = ' › ' } },
        lualine_x = { 'diagnostics', 'filetype' }, lualine_y = { 'progress' }, lualine_z = { 'location' } },
      extensions = { 'fugitive', 'oil', 'quickfix' } })
  end },
  { 'folke/flash.nvim', event = 'VeryLazy', opts = { modes = { char = { enabled = false } } },
    keys = {
      map('s', function() require('flash').jump() end, 'Flash jump'),
      map('S', function() require('flash').treesitter() end, 'Flash treesitter'),
      { 'r', function() require('flash').remote() end, mode = 'o', desc = 'Remote flash' },
      { 'R', function() require('flash').treesitter_search() end, mode = { 'o', 'x' }, desc = 'Treesitter search' } } },
  { 'folke/todo-comments.nvim', event = { 'BufReadPost', 'BufNewFile' }, dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
    keys = {
      map(']t', function() require('todo-comments').jump_next() end, 'Next TODO'),
      map('[t', function() require('todo-comments').jump_prev() end, 'Previous TODO'),
      map('<leader>xt', '<cmd>Trouble todo toggle<cr>', 'TODO list') } },
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = {},
    keys = {
      map('<leader>qs', function() require('persistence').load() end, 'Restore session'),
      map('<leader>ql', function() require('persistence').load({ last = true }) end, 'Last session'),
      map('<leader>qd', function() require('persistence').stop() end, 'Do not save session') } },
}
