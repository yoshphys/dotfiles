-- lua_add {{{
vim.keymap.set('n', "[Space]s", function()
  vim.fn["ddt#start"]({
    name = vim.t["ddt_ui_shell_last_name"] or ("shell-" .. vim.fn.win_getid()),
    ui = "shell",
  })
end, { desc = "ddt: open the shell UI (reuse the last one of the tab)" })
vim.keymap.set('n', "[Space]t", function()
  vim.fn["ddt#start"]({
    name = vim.t["ddt_ui_terminal_last_name"] or ("terminal-" .. vim.fn.win_getid()),
    ui = "terminal",
  })
end, { desc = "ddt: open the terminal UI (reuse the last one of the tab)" })
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

-- Define ANSI color highlight groups from the Catppuccin Mocha palette.
-- Hardcoded (catppuccin/vim has no Lua palette module, unlike the former
-- catppuccin/nvim) since ddt.vim is slated for removal anyway.
local ansi_map = {
  "#F38BA8", -- 01: red
  "#A6E3A1", -- 02: green
  "#F9E2AF", -- 03: yellow
  "#89B4FA", -- 04: blue
  "#F5C2E7", -- 05: magenta (pink)
  "#89DCEB", -- 06: cyan (sky)
  "#CDD6F4", -- 07: white (text)
  "#7F849C", -- 08: bright black (overlay1)
  "#EBA0AC", -- 09: bright red (maroon)
  "#A6E3A1", -- 10: bright green
  "#F9E2AF", -- 11: bright yellow
  "#B4BEFE", -- 12: bright blue (lavender)
  "#F5C2E7", -- 13: bright magenta (pink)
  "#94E2D5", -- 14: bright cyan (teal)
  "#CDD6F4", -- 15: bright white (text)
}
for i, color in ipairs(ansi_map) do
  local color_id = string.format("%02d", i)
  vim.api.nvim_set_hl(0, 'DDTShellFg' .. color_id, { fg = color })
  vim.api.nvim_set_hl(0, 'DDTShellBg' .. color_id, { bg = color })
end

vim.keymap.set('c', "<C-t>", "<Tab>", { desc = "Cmdline: insert a native <Tab> (<Tab> is used to select pum candidates)" })
vim.keymap.set('c', "<Tab>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#select_relative"](1)
  else
    -- vim.fn["feedkeys"]("<Tab>")
    return "<Tab>"
  end
end, { desc = "Cmdline: select the next pum candidate, otherwise fall back to <Tab>" })

-- }}}

-- lua_ddt-terminal {{{
vim.keymap.set('t', "<C-]>", "<C-\\><C-n>", { desc = "Terminal: go to normal mode" }) -- map <C-]> to go to normal mode
vim.keymap.set('n', "<C-n>", function()
  vim.fn["ddt#ui#do_action"]("nextPrompt")
end, { buffer = true, desc = "ddt-terminal: jump to the next prompt" })
vim.keymap.set('n', "<C-p>", function()
  vim.fn["ddt#ui#do_action"]("previousPrompt")
end, { buffer = true, desc = "ddt-terminal: jump to the previous prompt" })
vim.keymap.set('n', "<C-y>", function()
  vim.fn["ddt#ui#do_action"]("pastePrompt")
end, { buffer = true, desc = "ddt-terminal: paste the command of the current line to the prompt" })
vim.keymap.set('n', "<CR>", function()
  vim.fn["ddt#ui#do_action"]("executeLine")
end, { buffer = true, desc = "ddt-terminal: execute the command of the current line" })
vim.keymap.set('n', "[Space]gd", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git diff',
  })
end, { buffer = true, desc = "ddt-terminal: send `git diff`" })
vim.keymap.set('n', "[Space]gc", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit',
  })
end, { buffer = true, desc = "ddt-terminal: send `git commit`" })
vim.keymap.set('n', "[Space]gs", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git status',
  })
end, { buffer = true, desc = "ddt-terminal: send `git status`" })
vim.keymap.set('n', "[Space]gA", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit --amend',
  })
end, { buffer = true, desc = "ddt-terminal: send `git commit --amend`" })

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
end, { buffer = true, desc = "ddt-shell: jump to the next prompt" })
vim.keymap.set('n', "<C-p>", function()
  vim.fn["ddt#ui#do_action"]("previousPrompt")
end, { buffer = true, desc = "ddt-shell: jump to the previous prompt" })
vim.keymap.set('n', "<C-y>", function()
  vim.fn["ddt#ui#do_action"]("pastePrompt")
end, { buffer = true, desc = "ddt-shell: paste the command of the current line to the prompt" })
vim.keymap.set({'n', 'i'}, "<CR>", function()
  vim.fn["ddt#ui#do_action"]("executeLine")
end, { buffer = true, desc = "ddt-shell: execute the command of the current line" })
vim.keymap.set('n', "<C-c>", function()
  vim.fn["ddt#ui#do_action"]("terminate")
end, { buffer = true, desc = "ddt-shell: terminate the running command" })
vim.keymap.set('n', "[Space]gd", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git diff',
  })
end, { buffer = true, desc = "ddt-shell: send `git diff`" })
vim.keymap.set('n', "[Space]gc", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit',
  })
end, { buffer = true, desc = "ddt-shell: send `git commit`" })
vim.keymap.set('n', "[Space]gs", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git status',
  })
end, { buffer = true, desc = "ddt-shell: send `git status`" })
vim.keymap.set('n', "[Space]gA", function()
  vim.fn["ddt#ui#do_action"]('send', {
    str = 'git commit --amend',
  })
end, { buffer = true, desc = "ddt-shell: send `git commit --amend`" })
vim.keymap.set('i', "<C-n>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#insert_relative"](1, "empty")
  else
    vim.fn["ddc#map#manual_complete"]({
      sources = { 'shell_history' },
    })
  end
end, { buffer = true, desc = "ddt-shell: select the next candidate, or complete from shell history" })
vim.keymap.set('i', "<C-p>", function()
  if vim.fn["pum#visible"]() then
    vim.fn["pum#map#insert_relative"](-1, "empty")
  else
    vim.fn["ddc#map#manual_complete"]({
      sources = { 'shell_history' },
    })
  end
end, { buffer = true, desc = "ddt-shell: select the previous candidate, or complete from shell history" })
vim.keymap.set('n', "<C-h>", function()
  vim.fn["ddu#start"]({
    name   = "ddt",
    sync   = true,
    input  = vim.fn["ddt#ui#get_input"](),
    sources = { { name = "ddt_shell_history" } },
  })
end, { buffer = true, desc = "ddt-shell: search the shell history with ddu using the current input" })

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
