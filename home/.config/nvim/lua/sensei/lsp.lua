local M = {}
function M.setup()
  require('mason').setup({ PATH = 'append', ui = { border = 'single' } })
  local env = require('sensei.environment')
  local capabilities = require('blink.cmp').get_lsp_capabilities()
  local servers = {
    basedpyright = { settings = { python = { pythonPath = env.python() },
      basedpyright = { disableOrganizeImports = true, analysis = { diagnosticMode = 'openFilesOnly',
        typeCheckingMode = 'basic', autoSearchPaths = true, autoImportCompletions = true,
        -- ROS setup scripts expose built interfaces and site-packages here.
        extraPaths = vim.split(vim.env.PYTHONPATH or '', ':', { trimempty = true }) } } } },
    ruff = { init_options = { settings = { configurationPreference = 'filesystemFirst' } } },
    clangd = { cmd = { 'clangd', '--background-index', '-j=2', '--pch-storage=disk', '--header-insertion=never' } },
    lua_ls = { settings = { Lua = { completion = { callSnippet = 'Replace' }, telemetry = { enable = false } } } },
    ts_ls = {}, html = {}, cssls = {}, jsonls = {}, yamlls = { settings = { yaml = { keyOrdering = false } } },
    bashls = {}, cmake = {}, dockerls = {}, lemminx = {},
  }
  local qml = vim.fn.exepath('qmlls')
  if qml == '' and vim.fn.executable('/usr/lib/qt6/bin/qmlls') == 1 then qml = '/usr/lib/qt6/bin/qmlls' end
  if qml ~= '' then servers.qmlls = { cmd = { qml } } end
  -- Optional language profiles are enabled only when their tool is installed.
  if vim.fn.executable('rust-analyzer') == 1 then servers.rust_analyzer = {} end
  if vim.fn.executable('gopls') == 1 then servers.gopls = {} end
  for name, config in pairs(servers) do
    config.capabilities = capabilities
    config.root_dir = config.root_dir or function(bufnr, on_dir)
      if vim.b[bufnr].sensei_bigfile then return end
      local defaults = vim.lsp.config[name]
      local p = env.profile()
      if name == 'basedpyright' or name == 'ruff' then on_dir(p.root)
      else on_dir(vim.fs.root(bufnr, defaults and defaults.root_markers or { '.git' }) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))) end
    end
    vim.lsp.config(name, config)
    local defaults = vim.lsp.config[name]
    local cmd = config.cmd or (defaults and defaults.cmd)
    if type(cmd) == 'table' and vim.fn.executable(cmd[1]) == 1 then vim.lsp.enable(name) end
  end
  vim.api.nvim_create_autocmd('LspAttach', { group = vim.api.nvim_create_augroup('SenseiLsp', { clear = true }), callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == 'ruff' then client.server_capabilities.hoverProvider = false end
    local function key(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc }) end
    key('gd', function() require('fzf-lua').lsp_definitions() end, 'Definition')
    key('gD', vim.lsp.buf.declaration, 'Declaration')
    key('grr', function() require('fzf-lua').lsp_references() end, 'References')
    key('gri', function() require('fzf-lua').lsp_implementations() end, 'Implementations')
    key('grt', function() require('fzf-lua').lsp_typedefs() end, 'Type definition')
    key('K', vim.lsp.buf.hover, 'Documentation')
    key('<leader>cn', vim.lsp.buf.rename, 'Rename symbol')
    key('<leader>ca', vim.lsp.buf.code_action, 'Code actions')
    key('<leader>cs', vim.lsp.buf.signature_help, 'Signature help')
    key('<leader>ci', vim.lsp.buf.incoming_calls, 'Incoming calls')
    key('<leader>cO', vim.lsp.buf.outgoing_calls, 'Outgoing calls')
    key('<leader>ch', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf }) end, 'Toggle inlay hints')
  end })
end
return M
