-- Explicit, local field notes. Never opens automatically or reads buffer contents.
local recent, turn = {}, 0
vim.api.nvim_create_user_command('DenTip', function()
  local home = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
  local path = home .. '/.local/share/sensei-companion/notes.json'
  local ok, notes = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), '\n')) end)
  if not ok then vim.notify('Den field notes are not installed here.', vim.log.levels.INFO); return end
  turn = turn + 1
  local kind = turn % 3 == 0 and 'wit' or 'tip'
  local choices = vim.tbl_filter(function(n)
    return n.kind == kind and (#n.contexts == 0 or vim.tbl_contains(n.contexts, 'editor'))
      and not vim.tbl_contains(recent, n.text)
  end, notes)
  if #choices == 0 then recent = {}; vim.cmd.DenTip(); return end
  local note = choices[math.random(#choices)]
  recent[#recent + 1] = note.text
  if #recent > 8 then table.remove(recent, 1) end
  local lines = vim.split(note.text, '\n')
  local width = math.max(1, math.min(66, vim.o.columns - 8))
  local wrapped = {}
  for _, line in ipairs(lines) do
    while vim.fn.strdisplaywidth(line) > width do
      local part = line:sub(1, width):match('^(.*)%s') or line:sub(1, width)
      wrapped[#wrapped + 1] = part
      line = vim.trim(line:sub(#part + 1))
    end
    wrapped[#wrapped + 1] = line
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, wrapped)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false
  local win = vim.api.nvim_open_win(buf, true, { relative = 'editor', width = width,
    height = #wrapped, row = math.max(1, math.floor((vim.o.lines - #wrapped) / 2) - 2),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)), style = 'minimal',
    border = 'rounded', title = kind == 'wit' and ' Den · off the clock ' or ' Den · field note ', title_pos = 'center' })
  vim.wo[win].winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle'
  for _, key in ipairs({ 'q', '<Esc>', '<CR>' }) do
    vim.keymap.set('n', key, function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end,
      { buffer = buf, nowait = true })
  end
end, { desc = 'A local engineering tip or occasional small joke' })
