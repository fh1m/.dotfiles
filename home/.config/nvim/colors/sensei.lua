vim.cmd('highlight clear')
vim.g.colors_name = 'sensei'
local p = { bg = '#090807', black = '#000000', surface = '#171311', text = '#e8e2da',
  muted = '#a9a29a', dim = '#706963', pink = '#f23d70', light = '#ff80a3',
  green = '#9dbf9e', blue = '#a6b9d1', warn = '#d6b59a', error = '#ff567a' }
-- Share the existing wallpaper palette when available; retain durable fallback.
local palette_path = vim.fn.expand('~/.config/sensei/wallpaper-palette.json')
local ok, live = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(palette_path), '\n')) end)
if ok and type(live) == 'table' then
  for key, field in pairs({ bg = 'ground', surface = 'surface', text = 'text', muted = 'muted', pink = 'primary', light = 'vibrant' }) do
    if type(live[field]) == 'string' and live[field]:match('^#%x%x%x%x%x%x$') then p[key] = live[field] end
  end
end
local function h(name, opts) vim.api.nvim_set_hl(0, name, opts) end
h('Normal', { fg = p.text, bg = p.bg })
h('NormalFloat', { fg = p.text, bg = p.surface })
h('FloatBorder', { fg = p.dim, bg = p.surface })
h('FloatTitle', { fg = p.pink, bg = p.surface, bold = true })
h('Comment', { fg = p.muted })
h('LineNr', { fg = p.dim })
h('CursorLineNr', { fg = p.pink, bold = true })
h('CursorLine', { bg = p.bg })
h('SignColumn', { bg = p.bg })
h('EndOfBuffer', { fg = p.bg })
h('Visual', { bg = '#4c2231' })
h('Search', { fg = p.black, bg = p.light })
h('IncSearch', { fg = p.black, bg = p.pink, bold = true })
h('MatchParen', { fg = p.pink, bg = '#38202a', bold = true })
h('Pmenu', { fg = p.text, bg = p.surface })
h('PmenuSel', { fg = p.black, bg = p.pink, bold = true })
h('PmenuSbar', { bg = p.surface })
h('PmenuThumb', { bg = p.dim })
h('StatusLine', { fg = p.text, bg = p.surface })
h('StatusLineNC', { fg = p.dim, bg = p.bg })
h('WinSeparator', { fg = '#4c3b3b' })
for _, n in ipairs({ 'Statement', 'Keyword', 'Conditional', 'Repeat', 'Exception', 'Operator' }) do h(n, { fg = p.pink }) end
for _, n in ipairs({ 'String', 'Character' }) do h(n, { fg = p.green }) end
for _, n in ipairs({ 'Function', 'Identifier' }) do h(n, { fg = p.text }) end
for _, n in ipairs({ 'Type', 'Structure', 'Typedef' }) do h(n, { fg = p.blue }) end
for _, n in ipairs({ 'Number', 'Boolean', 'Constant', 'Float' }) do h(n, { fg = p.light }) end
h('PreProc', { fg = p.warn })
h('Special', { fg = p.warn })
h('Delimiter', { fg = p.muted })
h('Title', { fg = p.pink, bold = true })
h('Directory', { fg = p.blue })
h('NonText', { fg = p.dim })
h('Whitespace', { fg = '#37302c' })
h('Todo', { fg = p.black, bg = p.pink, bold = true })
for name, color in pairs({ Error = p.error, Warn = p.warn, Info = p.blue, Hint = p.muted }) do
  h('Diagnostic' .. name, { fg = color })
  h('DiagnosticUnderline' .. name, { sp = color, undercurl = true })
end
for name, color in pairs({ Add = p.green, Change = p.blue, Delete = p.error }) do
  h('GitSigns' .. name, { fg = color })
  h('Diff' .. name, { bg = ({ Add = '#18251c', Change = '#1a222e', Delete = '#30151e' })[name] })
end
h('DiffText', { bg = '#383045', bold = true })
h('@variable', { fg = p.text })
h('@variable.parameter', { fg = '#d0c4b7' })
h('@variable.builtin', { fg = p.light })
h('@function', { fg = p.text, bold = true })
h('@function.builtin', { fg = p.blue })
h('@markup.heading', { fg = p.pink, bold = true })
h('@markup.link', { fg = p.blue, underline = true })
h('@markup.raw', { fg = p.green })
h('LspReferenceText', { bg = '#292020' })
h('LspReferenceRead', { link = 'LspReferenceText' })
h('LspReferenceWrite', { link = 'LspReferenceText' })

-- ANSI output in :terminal agrees with the outer terminal, not rainbow defaults.
local ansi = { '#171311', p.error, p.green, p.warn, p.blue, p.pink, '#76bcc0', p.text,
  p.dim, '#ff8099', '#b5d3b1', '#e8caa9', '#c1d0e4', p.light, '#9bd4d6', '#fff3ea' }
for i, color in ipairs(ansi) do vim.g['terminal_color_' .. (i - 1)] = color end
h('DiagnosticFloatingError', { fg = p.error, bg = p.surface })
h('DiagnosticFloatingWarn', { fg = p.warn, bg = p.surface })
h('DiagnosticFloatingInfo', { fg = p.blue, bg = p.surface })
h('DiagnosticFloatingHint', { fg = p.muted, bg = p.surface })
h('WinBar', { fg = p.muted, bg = p.bg })
h('WinBarNC', { fg = p.dim, bg = p.bg })
