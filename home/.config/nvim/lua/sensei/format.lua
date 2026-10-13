local M = {}
local function configured(buf)
  if vim.b[buf].sensei_bigfile then return false end
  local name = vim.api.nvim_buf_get_name(buf)
  if name:match('/build/') or name:match('/install/') or name:match('/node_modules/') then return false end
  local root = require('sensei.environment').profile().root
  local dir = vim.fs.dirname(name)
  local markers = { python = { 'ruff.toml', '.ruff.toml' }, cpp = { '.clang-format' }, c = { '.clang-format' },
    lua = { 'stylua.toml', '.stylua.toml' }, javascript = { '.prettierrc', '.prettierrc.json', 'prettier.config.js', '.prettierrc.yaml' },
    typescript = { '.prettierrc', '.prettierrc.json', 'prettier.config.js', '.prettierrc.yaml' } }
  local ft = vim.bo[buf].filetype
  if ft == 'javascriptreact' then ft = 'javascript' elseif ft == 'typescriptreact' then ft = 'typescript' end
  if vim.fs.find(markers[ft] or {}, { path = dir, upward = true, stop = vim.fs.dirname(root) })[1] then return true end
  if ft == 'python' then
    local f = io.open(root .. '/pyproject.toml')
    if f then local text = f:read('*a'); f:close(); return text:find('%[tool%.ruff') ~= nil or text:find('%[tool%.black%]') ~= nil end
  end
  return false
end
function M.setup()
  require('conform').setup({
    formatters_by_ft = { python = function(buf)
      local root = require('sensei.environment').profile().root
      local f = io.open(root .. '/pyproject.toml')
      local text = f and f:read('*a') or ''; if f then f:close() end
      return text:find('%[tool%.black%]') and not text:find('%[tool%.ruff') and { 'black' } or { 'ruff_format' }
    end, c = { 'clang_format' }, cpp = { 'clang_format' }, lua = { 'stylua' },
      javascript = { 'prettier' }, javascriptreact = { 'prettier' }, typescript = { 'prettier' },
      typescriptreact = { 'prettier' }, json = { 'prettier' }, yaml = { 'prettier' }, markdown = { 'prettier' }, sh = { 'shfmt' } },
    format_on_save = function(buf)
      if configured(buf) then return { timeout_ms = 300, lsp_format = 'never' } end
    end,
    notify_on_error = true,
  })
end
M.configured = configured
return M
