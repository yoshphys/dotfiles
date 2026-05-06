-- lua_add {{{
vim.keymap.set('n', "[Space]s", function()
  vim.fn["ddt#start"]({
    name = vim.t["ddt_ui_shell_last_name"] or ("shell-" .. vim.fn.win_getid()),
    ui = "shell",
  })
end)
vim.keymap.set('n', "[Space]t", function()
  vim.fn["ddt#start"]({
    name = vim.t["ddt_ui_terminal_last_name"] or ("terminal-" .. vim.fn.win_getid()),
    ui = "terminal",
  })
end)
-- }}}

-- lua_source {{{
local hook_source = vim.env.VIM_CONFIG_PATH .. "/rc/ts/ddt.ts"
vim.fn["ddt#custom#load_config"](hook_source)

local cached_status = {}

_G._my_git_status_impl = function()
  local gitdir = vim.fn.finddir('.git', ';')
  if gitdir == '' then
    return ''
  end

  local full_gitdir = vim.fn.fnamemodify(gitdir, ':p')
  local gitdir_time = vim.fn.getftime(full_gitdir)
  local now = vim.fn.localtime()

  local cache = cached_status[full_gitdir]
  if not cache
    or gitdir_time > cache.timestamp
    or now > cache.check + 1
  then
    local branch = vim.fn.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' })
    local stat   = vim.fn.system({ 'git', 'status', '--short', '--ignore-submodules=all' })
    local lines = vim.split(
      string.format(" %s%s", branch, stat):gsub('\n$', ''),
      '\n'
    )
    for i, v in ipairs(lines) do
      lines[i] = '| ' .. v
    end
    local status = table.concat(lines, '\n'):gsub('^| ', '')

    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if buf.changed == 1 and buf.name ~= '' then
        status = status .. '\n' .. string.format('| ?? %s (unsaved)',
          vim.fn.fnamemodify(buf.name, ':.'))
      end
    end

    cached_status[full_gitdir] = {
      check     = now,
      timestamp = gitdir_time,
      status    = status,
    }
  end

  return cached_status[full_gitdir].status
end

-- Expose as a Vimscript function for userPrompt evaluation
vim.cmd([[
  function! MyGitStatus() abort
    return luaeval('_G._my_git_status_impl()')
  endfunction
]])

-- Define ANSI color highlight groups from Catppuccin Mocha palette
local palette = require('catppuccin.palettes').get_palette('mocha')
local ansi_map = {
  palette.red,     -- 01: red
  palette.green,   -- 02: green
  palette.yellow,  -- 03: yellow
  palette.blue,    -- 04: blue
  palette.pink,    -- 05: magenta
  palette.sky,     -- 06: cyan
  palette.text,    -- 07: white
  palette.overlay1,-- 08: bright black
  palette.maroon,  -- 09: bright red
  palette.green,   -- 10: bright green
  palette.yellow,  -- 11: bright yellow
  palette.lavender,-- 12: bright blue
  palette.pink,    -- 13: bright magenta
  palette.teal,    -- 14: bright cyan
  palette.text,    -- 15: bright white
}
for i, color in ipairs(ansi_map) do
  local color_id = string.format("%02d", i)
  vim.api.nvim_set_hl(0, 'DDTShellFg' .. color_id, { fg = color })
  vim.api.nvim_set_hl(0, 'DDTShellBg' .. color_id, { bg = color })
end

vim.keymap.set('c', "<C-t>", "<Tab>")
vim.keymap.set('c', "<Tab>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#select_relative"](1)
  else
    -- vim.fn["feedkeys"]("<Tab>")
    return "<Tab>"
  end
end)

-- }}}

-- lua_ddt-terminal {{{
vim.keymap.set('t', "<C-]>", "<C-\\><C-n>") -- map <C-]> to go to normal mode
vim.keymap.set('n', "<C-n>", function()
  vim.fn["ddt#ui#do_action"]("nextPrompt")
end, { buffer = true })
vim.keymap.set('n', "<C-p>", function()
  vim.fn["ddt#ui#do_action"]("previousPrompt")
end, { buffer = true })
vim.keymap.set('n', "<C-y>", function()
  vim.fn["ddt#ui#do_action"]("pastePrompt")
end, { buffer = true })
vim.keymap.set('n', "<CR>", function()
  vim.fn["ddt#ui#do_action"]("executeLine")
end, { buffer = true })
vim.keymap.set('n', "[Space]gd", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git diff',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gc", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gs", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git status',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gA", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit --amend',
  })
end, { buffer = true })

vim.api.nvim_create_autocmd('DirChanged', {
  group = vim.api.nvim_create_augroup('ddt-ui-terminal', { clear = false }),
  buffer = 0,
  callback = function()
    local cwd = vim.v.event.cwd
    if cwd and vim.t['ddt_ui_last_directory'] ~= cwd then
      vim.fn["ddt#ui#do_action"]('cd', { directory = cwd })
    end
  end,
})
if vim.b['ddt_terminal_directory'] then
  vim.cmd.tcd(vim.fn.fnameescape(vim.b['ddt_terminal_directory']))
end
-- }}}

-- lua_ddt-shell {{{
vim.keymap.set('n', "<C-n>", function()
  vim.fn["ddt#ui#do_action"]("nextPrompt")
end, { buffer = true })
vim.keymap.set('n', "<C-p>", function()
  vim.fn["ddt#ui#do_action"]("previousPrompt")
end, { buffer = true })
vim.keymap.set('n', "<C-y>", function()
  vim.fn["ddt#ui#do_action"]("pastePrompt")
end, { buffer = true })
vim.keymap.set({'n', 'i'}, "<CR>", function()
  vim.fn["ddt#ui#do_action"]("executeLine")
end, { buffer = true })
vim.keymap.set('n', "<C-c>", function()
  vim.fn["ddt#ui#do_action"]("terminate")
end, { buffer = true })
vim.keymap.set('n', "[Space]gd", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git diff',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gc", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gs", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git status',
  })
end, { buffer = true })
vim.keymap.set('n', "[Space]gA", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit --amend',
  })
end, { buffer = true })
vim.keymap.set('i', "<C-n>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#insert_relative"](1, "empty")
  else
    vim.fn["ddc#map#manual_complete"]({
      sources = { 'shell_history' },
    })
  end
end, { buffer = true })
vim.keymap.set('i', "<C-p>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#insert_relative"](-1, "empty")
  else
    vim.fn["ddc#map#manual_complete"]({
      sources = { 'shell_history' },
    })
  end
end, { buffer = true })
vim.keymap.set('n', "<C-h>", function()
  vim.fn["ddu#start"]({
    name   = "ddt",
    sync   = true,
    input  = vim.fn["ddt#ui#get_input"](),
    sources = { { name = "ddt_shell_history" } },
  })
end, { buffer = true })

vim.api.nvim_create_autocmd('DirChanged', {
  group = vim.api.nvim_create_augroup('ddt-ui-shell', { clear = false }),
  buffer = 0,
  callback = function()
    local cwd = vim.v.event.cwd
    if cwd and vim.t['ddt_ui_last_directory'] ~= cwd then
      vim.fn["ddt#ui#do_action"]('cd', { directory = cwd })
    end
  end,
})
if vim.b['ddt_shell_directory'] then
  vim.cmd.tcd(vim.fn.fnameescape(vim.b['ddt_shell_directory']))
end
-- }}}
