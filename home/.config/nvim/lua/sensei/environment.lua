local M = {}
function M.profile()
  if vim.env.SENSEI_DEV_PROFILE then
    local ok, p = pcall(vim.json.decode, vim.env.SENSEI_DEV_PROFILE)
    if ok and type(p) == 'table' then return p end
  end
  local root = vim.fs.root(0, { '.git', 'colcon.meta', 'package.xml', 'pyproject.toml', 'package.json', 'CMakeLists.txt' }) or vim.fn.getcwd()
  local home = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
  local registry = home .. '/.local/state/sensei-dev/projects.json'
  local f = io.open(registry)
  if f then
    local ok, data = pcall(vim.json.decode, f:read('*a')); f:close()
    if ok then
      local best
      for _, p in ipairs(data.projects or {}) do
        if (root == p.root or root:sub(1, #p.root + 1) == p.root .. '/') and (not best or #p.root > #best.root) then best = p end
      end
      if best then return best end
    end
  end
  return { root = root, container = vim.env.CONTAINER_ID, python = vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. '/bin/python') or vim.fn.exepath('python3') }
end
function M.python()
  if M.selected_python then return M.selected_python end
  local p = M.profile()
  if p.python and vim.fn.executable(p.python) == 1 then return p.python end
  for _, name in ipairs({ '.venv/bin/python', 'venv/bin/python' }) do
    local candidate = p.root .. '/' .. name
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
  return vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. '/bin/python') or vim.fn.exepath('python3')
end
function M.label()
  local p = M.profile()
  local python = M.python()
  local name = python:match('/([^/]+)/bin/python[^/]*$')
  return (p.container or 'host') .. (name and name ~= 'usr' and (' / ' .. name) or '')
end
function M.select_python()
  local p = M.profile()
  local host = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
  local paths = { vim.fn.exepath('python3') }
  for _, dir in ipairs({ p.root, vim.fn.expand('~/Envs/python'), host .. '/Envs/python', vim.fn.expand('~/.venvs') }) do
    for _, path in ipairs(vim.fn.glob(dir .. '/*/bin/python*', false, true)) do
      if vim.fn.executable(path) == 1 and not path:match('config$') then table.insert(paths, path) end
    end
  end
  for _, name in ipairs({ '.venv/bin/python', 'venv/bin/python' }) do
    if vim.fn.executable(p.root .. '/' .. name) == 1 then table.insert(paths, p.root .. '/' .. name) end
  end
  paths = vim.fn.uniq(vim.fn.sort(paths))
  vim.ui.select(paths, { prompt = 'Interpreter (validated in this environment)' }, function(path)
    if not path then return end
    vim.system({ path, '-c', 'import sys; print(sys.executable)' }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then vim.notify('Interpreter cannot run here: ' .. (result.stderr or ''), vim.log.levels.ERROR); return end
        M.selected_python = path
        -- LSP, DAP and neotest all consult this single resolver.
        for _, client in ipairs(vim.lsp.get_clients({ name = 'basedpyright' })) do
          client.config.settings.python = { pythonPath = path }
          client:notify('workspace/didChangeConfiguration', { settings = client.config.settings })
        end
        local launcher = host .. '/.local/bin/sensei-dev'
        vim.system({ launcher, 'configure', p.root, '--python', path }, { text = true }, function(r)
          vim.schedule(function()
            vim.notify(r.code == 0 and ('Interpreter saved: ' .. path) or ('Selected for this editor; could not save: ' .. (r.stderr or '')), r.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
          end)
        end)
      end)
    end)
  end)
end
function M.setup()
  vim.api.nvim_create_user_command('DevInfo', function()
    local p = M.profile()
    p.resolved_python = M.python()
    p.neovim = vim.fn.exepath('nvim')
    p.pythonpath = vim.env.PYTHONPATH
    p.lsp = vim.tbl_map(function(c) return { name = c.name, root = c.config.root_dir, command = c.config.cmd } end, vim.lsp.get_clients())
    vim.notify(vim.inspect(p))
  end, { desc = 'Inspect project and tool environment' })
  vim.api.nvim_create_user_command('DevEnvironment', M.select_python, { desc = 'Select and save the Python interpreter' })
end
return M
