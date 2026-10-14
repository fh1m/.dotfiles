local M = {}
function M.config()
  local host = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
  local f = io.open(host .. '/.config/sensei-dev/knowledge.json')
  local data = {}
  if f then
    local ok, decoded = pcall(vim.json.decode, f:read('*a')); f:close()
    if ok then data = decoded end
  end
  local app = io.open(host .. '/.config/obsidian/obsidian.json')
  local registered = {}
  if app then
    local success, store = pcall(vim.json.decode, app:read('*a')); app:close()
    if success then for _, v in pairs(store.vaults or {}) do registered[#registered + 1] = v.path end end
  end
  for _, path in ipairs(data.extra_vaults or {}) do registered[#registered + 1] = path end
  if data.default_vault then table.insert(registered, 1, data.default_vault) end
  local seen, names = {}, {}
  data.vaults = {}
  for _, path in ipairs(registered) do
    if not seen[path] and vim.uv.fs_stat(path) then
      seen[path] = true
      local name = vim.fs.basename(path)
      if names[name] then name = name .. '-' .. vim.fn.sha256(path):sub(1, 6) end
      names[name] = true
      data.vaults[#data.vaults + 1] = { name = name, path = path }
    end
  end
  return data
end
function M.capture_range()
  local mode = vim.fn.mode()
  if mode:match('[vV\22]') then
    local a, b = vim.fn.line('v'), vim.fn.line('.')
    return math.min(a, b), math.max(a, b)
  end
  local ok, node = pcall(vim.treesitter.get_node)
  if ok then
    while node do
      if node:type():find('function') or node:type():find('method') then
        local a, _, b = node:range()
        return a + 1, math.min(b + 1, a + 300)
      end
      node = node:parent()
    end
  end
  return vim.fn.line('.'), math.min(vim.fn.line('.') + 29, vim.api.nvim_buf_line_count(0))
end
function M.open(kind)
  local host = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
  local p = require('sensei.environment').profile()
  local args = { host .. '/.local/bin/sensei-dev', 'knowledge', p.root, '--kind', kind }
  if kind == 'review' then
    local first, last = M.capture_range()
    -- Capture unsaved selection explicitly, without changing or autosaving code.
    local path = vim.fn.tempname() .. '.txt'
    vim.fn.writefile(vim.api.nvim_buf_get_lines(0, first - 1, last, false), path)
    -- /tmp is shared: the excerpt is source code, so keep it owner-only (0600).
    vim.uv.fs_chmod(path, 384)
    vim.list_extend(args, { '--excerpt', path, '--source-file', vim.api.nvim_buf_get_name(0), '--start', tostring(first), '--end', tostring(last), '--filetype', vim.bo.filetype })
  end
  vim.system(args, { text = true }, function(r)
    vim.schedule(function()
      for i, v in ipairs(args) do if v == '--excerpt' then vim.fn.delete(args[i + 1]) end end
      if r.code ~= 0 then vim.notify(r.stderr or 'Knowledge action failed', vim.log.levels.ERROR); return end
      local path = vim.trim(r.stdout or '')
      if kind == 'review' or kind == 'scratchpad' or kind == 'daily' or kind == 'project' then
        if vim.uv.fs_stat(path) then vim.cmd('vsplit ' .. vim.fn.fnameescape(path)) end
      end
    end)
  end)
end
function M.search_all()
  local paths = {}
  for _, v in ipairs(M.config().vaults or {}) do table.insert(paths, v.path) end
  if #paths == 0 then vim.notify('No vaults registered', vim.log.levels.WARN); return end
  require('fzf-lua').live_grep({ search_paths = paths, prompt = 'All vaults › ',
    rg_opts = '--column --line-number --no-heading --color=always --smart-case -g *.md -g !.obsidian -g !.git' })
end
return M
