local M = {}
function M.open(kind)
  if kind == 'guide' then
    vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath('config') .. '/LEARN.md'))
    return
  end
  require('sensei.knowledge').open(kind == 'note' and 'scratchpad' or 'review')
end
function M.docs()
  local word = vim.fn.expand('<cword>')
  local providers = {
    { 'Python reference', 'https://docs.python.org/3/search.html?q=' },
    { 'ROS 2 Humble', 'https://docs.ros.org/en/humble/search.html?q=' },
    { 'C / C++ reference', 'https://en.cppreference.com/mwiki/index.php?title=Special:Search&search=' },
    { 'MDN web reference', 'https://developer.mozilla.org/en-US/search?q=' },
    { 'Qt documentation', 'https://doc.qt.io/qt-6/search-results.html?q=' },
    { 'Neovim help (offline)', nil },
  }
  vim.ui.select(providers, { prompt = 'Look up ' .. word, format_item = function(v) return v[1] end }, function(v)
    if not v then return end
    if not v[2] then vim.cmd.help(word); return end
    local query = word:gsub('[^%w%-_.~]', function(c) return ('%%%02X'):format(c:byte()) end)
    local host = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
    vim.system({ host .. '/.local/bin/sensei-dev', 'browse', v[2] .. query }, { text = true }, function(r)
      if r.code ~= 0 then vim.schedule(function() vim.notify(r.stderr or 'Browser unavailable', vim.log.levels.ERROR) end) end
    end)
  end)
end
return M
