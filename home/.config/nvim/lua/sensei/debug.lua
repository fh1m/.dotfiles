local M = {}
function M.setup()
  local dap = require('dap')
  local python = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python'
  if vim.fn.executable(python) == 1 then
    require('dap-python').setup(python)
    require('dap-python').resolve_python = require('sensei.environment').python
  end
  local codelldb = vim.fn.exepath('codelldb')
  if codelldb ~= '' then
    dap.adapters.codelldb = { type = 'executable', command = codelldb }
    local launch = { name = 'Launch compiled program', type = 'codelldb', request = 'launch',
      program = function() return vim.fn.input('Executable: ', require('sensei.environment').profile().root .. '/', 'file') end,
      cwd = function() return require('sensei.environment').profile().root end, stopOnEntry = false }
    dap.configurations.cpp = { launch }; dap.configurations.c = { launch }; dap.configurations.rust = { launch }
  end
  require('dapui').setup({ controls = { enabled = false },
    layouts = { { elements = { { id = 'scopes', size = 0.6 }, { id = 'breakpoints', size = 0.2 }, { id = 'stacks', size = 0.2 } }, size = 42, position = 'left' },
      { elements = { { id = 'repl', size = 0.5 }, { id = 'console', size = 0.5 } }, size = 10, position = 'bottom' } }, floating = { border = 'single' } })
  dap.listeners.after.event_initialized.sensei = function() require('dapui').open() end
  dap.listeners.before.event_terminated.sensei = function() require('dapui').close() end
  dap.listeners.before.event_exited.sensei = function() require('dapui').close() end
end
return M
