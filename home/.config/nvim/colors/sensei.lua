vim.cmd('highlight clear')
vim.g.colors_name = 'sensei'
local p = { bg = '#090807', black = '#000000', surface = '#171311', text = '#e8e2da',
  muted = '#a9a29a', dim = '#706963', pink = '#f23d70', light = '#ff80a3',
  green = '#9dbf9e', blue = '#a6b9d1', warn = '#d6b59a', error = '#ff567a' }
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
