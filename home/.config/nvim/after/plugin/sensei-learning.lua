-- Additive Noesis bridge: coding stays here, durable models stay in Markdown.
local executable = vim.fn.expand('~/.local/bin/noesis')
local function run(args)
  if vim.fn.executable(executable) ~= 1 then vim.notify('Noesis is not installed', vim.log.levels.ERROR); return end
  if args[1] ~= 'window' and args[1] ~= 'use' then
    local scope=vim.env.NOESIS_VAULT
    if not scope or scope=='' then
      local ok,config=pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.expand('~/.config/sensei-learning/config.json')), '\n'))
      end)
      if ok then scope=config.active_vault end
    end
    if scope and scope~='' then
      table.insert(args,2,'--vault');table.insert(args,3,scope)
    end
    if args[1]=='capture' and vim.env.NOESIS_RECORD_ID and vim.env.NOESIS_RECORD_ID~='' then
      table.insert(args,2,'--context-id');table.insert(args,3,vim.env.NOESIS_RECORD_ID)
    end
  end
  vim.system(vim.list_extend({executable}, args), {text=true}, function(result)
    if result.code ~= 0 then vim.schedule(function() vim.notify(result.stderr or 'Noesis action failed', vim.log.levels.ERROR) end) end
  end)
end
for key, command in pairs({ow='window', oo='open', of='frontier', od='today', ob='backup'}) do
  vim.keymap.set('n', '<leader>'..key, function() run({command}) end, {desc='Noesis: '..command})
end
vim.keymap.set('n', '<leader>oc', function()
  vim.ui.input({prompt='Noesis observation / question: '}, function(text)
    if text and text:match('%S') then
      local file=vim.fn.expand('%:p');local cwd=vim.fs.root(file,{'.git'}) or vim.fn.getcwd()
      local hash=vim.fn.system({'git','-C',cwd,'rev-parse','HEAD'}):gsub('%s+$','')
      local context = '\n\nCode context: `'..file..':'..vim.fn.line('.')..'`\nCommit: `'..(vim.v.shell_error==0 and hash or 'not in Git')..'`\n'
      run({'capture', text..context})
    end
  end)
end, {desc='Noesis: capture with code context'})
vim.keymap.set('n', '<leader>os', function()
  vim.ui.input({prompt='Search knowledge: '}, function(query)
    if query and query:match('%S') then run({'cli','search:open','query='..query}) end
  end)
end, {desc='Noesis: search knowledge'})
vim.api.nvim_create_user_command('Noesis', function(opts) run({opts.args ~= '' and opts.args or 'open'}) end,
  {nargs='?', complete=function() return {'window','open','frontier','today','backup'} end})
-- Normal editor surfaces follow the terminal; floating menus keep their surfaces.
local function transparent()
  for _, group in ipairs({'Normal','NormalNC','SignColumn','EndOfBuffer'}) do
    local hl=vim.api.nvim_get_hl(0,{name=group,link=false});hl.bg=nil;vim.api.nvim_set_hl(0,group,hl)
  end
end
vim.api.nvim_create_autocmd('ColorScheme',{callback=transparent})
transparent()

vim.api.nvim_create_autocmd("User", {pattern="VeryLazy", callback=function()
  local ok, wk=pcall(require,"which-key");if ok then wk.add({{"<leader>o",group="Noesis / learn"}}) end
end})

vim.keymap.set('v','<leader>og',function()
  local first=vim.fn.line("'<");local last=vim.fn.line("'>")
  local lines=vim.api.nvim_buf_get_lines(0,first-1,last,false)
  local file=vim.fn.expand('%:p');local kind=vim.bo.filetype
  local root=vim.fs.root(file,{'.git'}) or vim.fn.getcwd()
  local hash=vim.fn.system({'git','-C',root,'rev-parse','HEAD'}):gsub('%s+$','')
  if vim.v.shell_error~=0 then hash='not in Git' end
  run({'capture','--kind','snippet','## Gold snippet\nSource: `'..file..':'..first..'-'..last..'`\nCommit: `'..hash..'`\n\n```'..kind..'\n'..table.concat(lines,'\n')..'\n```\n\nWhy useful / assumptions / where verified:\n'})
end,{desc='Noesis: capture selected code with provenance'})
