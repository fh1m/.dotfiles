-- Additive Oasis bridge: coding stays here, durable models stay in Markdown.
local executable = vim.fn.expand('~/.local/bin/oasis')
local function run(args)
  if vim.fn.executable(executable) ~= 1 then vim.notify('Oasis is not installed', vim.log.levels.ERROR); return end
  vim.system(vim.list_extend({executable}, args), {text=true}, function(result)
    if result.code ~= 0 then vim.schedule(function() vim.notify(result.stderr or 'Oasis action failed', vim.log.levels.ERROR) end) end
  end)
end
for key, command in pairs({oo='open', of='frontier', od='today', ob='backup'}) do
  vim.keymap.set('n', '<leader>'..key, function() run({command}) end, {desc='Oasis: '..command})
end
vim.keymap.set('n', '<leader>oc', function()
  vim.ui.input({prompt='Oasis observation / question: '}, function(text)
    if text and text:match('%S') then
      local context = '\n\nCode context: `'..vim.fn.expand('%:p')..':'..vim.fn.line('.')..'`\n'
      run({'capture', text..context})
    end
  end)
end, {desc='Oasis: capture with code context'})
vim.keymap.set('n', '<leader>os', function()
  vim.ui.input({prompt='Search knowledge: '}, function(query)
    if query and query:match('%S') then run({'cli','search:open','query='..query}) end
  end)
end, {desc='Oasis: search knowledge'})
vim.api.nvim_create_user_command('Oasis', function(opts) run({opts.args ~= '' and opts.args or 'open'}) end,
  {nargs='?', complete=function() return {'open','frontier','today','backup'} end})
-- Normal editor surfaces follow the terminal; floating menus keep their surfaces.
local function transparent()
  for _, group in ipairs({'Normal','NormalNC','SignColumn','EndOfBuffer'}) do
    local hl=vim.api.nvim_get_hl(0,{name=group,link=false});hl.bg=nil;vim.api.nvim_set_hl(0,group,hl)
  end
end
vim.api.nvim_create_autocmd('ColorScheme',{callback=transparent})
transparent()

vim.api.nvim_create_autocmd("User", {pattern="VeryLazy", callback=function()
  local ok, wk=pcall(require,"which-key");if ok then wk.add({{"<leader>o",group="Oasis / learn"}}) end
end})
