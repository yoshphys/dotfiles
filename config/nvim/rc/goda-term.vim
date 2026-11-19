" hooks_file for Shougo/goda-term.vim, the successor of Shougo/ddt.vim:
" ported from the former rc/ddt.lua (lua_add/lua_source/lua_ddt-terminal/
" lua_ddt-shell blocks) and rc/ts/ddt.ts (the Deno config, now replaced by
" rc/goda-term/main.go). See `:help goda-term-ddt` for the API renames
" (ddt#... -> goda_term#..., filetypes ddt-ui-shell/ddt-ui-terminal ->
" goda-term-shell/goda-term-terminal).
"
" The old ddt.vim <C-h> shell-history search is now <C-r> (goda-term-shell
" only, below) over rc/lese/custom.lua's "shellhistory" picker, which
" reads the same files as goda-cmp's shellhistory source (see
" rc/goda-cmp/main.go's shellHistories).
"
" The old b:ddt_*_directory auto-tcd needed no porting: goda-term-ui-
" shell.vim's own goda_term#ui#shell#_cd() already calls chdir() + fires
" DirChanged when the embedded shell's own cwd changes, which the
" DirChanged autocmd below (the opposite direction: Vim's cwd -> the UI)
" already guards against looping back on.

" hook_add {{{
" Unset, this defaults to stdpath('config') .. '/goda-term' (no "rc/"),
" which isn't where ours lives.
let g:goda_term#config_dir = $VIM_CONFIG_PATH .. '/rc/goda-term'

" Force-rebuild the Go binary from main.go, the same reason as
" :GodaPmBuild in goda-pm.vim: every file under $VIM_CONFIG_PATH is
" deployed read-only from the Nix store (mtime fixed at the epoch), so
" goda-term's own "no binary yet" auto-build can misfire; run this
" explicitly after editing rc/goda-term/main.go.
command! GodaTermBuild call goda_term#build()

nnoremap [Space]s <Cmd>call goda_term#start(#{
      \   name: t:->get('goda_term_ui_shell_last_name',
      \                 'shell-' .. win_getid()),
      \   ui: 'shell',
      \ })<CR>
nnoremap [Space]t <Cmd>call goda_term#start(#{
      \   name: t:->get('goda_term_ui_terminal_last_name',
      \                 'terminal-' .. win_getid()),
      \   ui: 'terminal',
      \ })<CR>
" }}}

" hook_source {{{
let s:cached_status = {}

function MyGitStatus() abort
  let gitdir = finddir('.git', ';')
  if gitdir ==# ''
    return ''
  endif

  let full_gitdir = fnamemodify(gitdir, ':p')
  let gitdir_time = getftime(full_gitdir)
  let now = localtime()

  if !has_key(s:cached_status, full_gitdir)
        \ || gitdir_time > s:cached_status[full_gitdir].timestamp
        \ || now > s:cached_status[full_gitdir].check + 1
    let branch = system(['git', 'rev-parse', '--abbrev-ref', 'HEAD'])
    let stat = system(['git', 'status', '--short', '--ignore-submodules=all'])
    let lines = split(substitute(' ' .. branch .. stat, '\n$', '', ''), '\n')
    call map(lines, { _, v -> '| ' .. v })
    let status = substitute(join(lines, "\n"), '^| ', '', '')

    for buf in getbufinfo(#{ buflisted: 1 })
      if buf.changed && buf.name !=# ''
        let status ..= "\n" .. printf('| ?? %s (unsaved)', fnamemodify(buf.name, ':.'))
      endif
    endfor

    let s:cached_status[full_gitdir] = #{
          \ check: now,
          \ timestamp: gitdir_time,
          \ status: status,
          \ }
  endif

  return s:cached_status[full_gitdir].status
endfunction

" ANSI color highlight groups from the Catppuccin Mocha palette (0/black is
" left at the terminal's default; see rc/goda-term/main.go's fgs/bgs).
let s:ansi_colors = [
      \ '#F38BA8', '#A6E3A1', '#F9E2AF', '#89B4FA', '#F5C2E7', '#89DCEB',
      \ '#CDD6F4', '#7F849C', '#EBA0AC', '#A6E3A1', '#F9E2AF', '#B4BEFE',
      \ '#F5C2E7', '#94E2D5', '#CDD6F4',
      \ ]
for s:i in range(1, 15)
  execute printf('highlight GodaTermFg%02d guifg=%s', s:i, s:ansi_colors[s:i - 1])
  execute printf('highlight GodaTermBg%02d guibg=%s', s:i, s:ansi_colors[s:i - 1])
endfor
unlet s:i

" Cmdline: <Tab> selects the next pum candidate (only when pum is visible:
" it does nothing, not even inserting a tab, otherwise); <C-t> for a literal
" tab.
cnoremap <C-t> <Tab>
cnoremap <Tab> <Cmd>if pum#visible() \| call pum#map#select_relative(1) \| endif<CR>
" }}}

" goda-term-terminal {{{
tnoremap <buffer> <C-]> <C-\><C-n>
" Without these, <C-n>/<C-p> while actually typing (terminal-job mode) go to
" the job itself instead of goda-term's own prompt navigation.
tnoremap <buffer> <C-n> <Cmd>call goda_term#ui#do_action('nextPrompt')<CR>
tnoremap <buffer> <C-p> <Cmd>call goda_term#ui#do_action('previousPrompt')<CR>
nnoremap <buffer> <C-n> <Cmd>call goda_term#ui#do_action('nextPrompt')<CR>
nnoremap <buffer> <C-p> <Cmd>call goda_term#ui#do_action('previousPrompt')<CR>
nnoremap <buffer> <C-y> <Cmd>call goda_term#ui#do_action('pastePrompt')<CR>
nnoremap <buffer> <CR> <Cmd>call goda_term#ui#do_action('executeLine')<CR>
nnoremap <buffer> [Space]gd <Cmd>call goda_term#ui#do_action('send', #{ str: 'git diff' })<CR>
nnoremap <buffer> [Space]gc <Cmd>call goda_term#ui#do_action('send', #{ str: 'git commit' })<CR>
nnoremap <buffer> [Space]gs <Cmd>call goda_term#ui#do_action('send', #{ str: 'git status' })<CR>
nnoremap <buffer> [Space]gA <Cmd>call goda_term#ui#do_action('send', #{ str: 'git commit --amend' })<CR>

augroup goda-term-ui-terminal
  autocmd! * <buffer>
  autocmd DirChanged <buffer>
        \ : if (v:event->has_key('cwd')
        \       && t:->get('goda_term_ui_last_directory') !=# v:event.cwd)
        \ |   call goda_term#ui#do_action('cd', #{ directory: v:event.cwd })
        \ | endif
augroup END
" }}}

" goda-term-shell {{{
nnoremap <buffer> <C-n> <Cmd>call goda_term#ui#do_action('nextPrompt')<CR>
nnoremap <buffer> <C-p> <Cmd>call goda_term#ui#do_action('previousPrompt')<CR>
nnoremap <buffer> <C-y> <Cmd>call goda_term#ui#do_action('pastePrompt')<CR>
nnoremap <buffer> <CR> <Cmd>call goda_term#ui#do_action('executeLine')<CR>
inoremap <buffer> <CR> <Cmd>call goda_term#ui#do_action('executeLine')<CR>
nnoremap <buffer> <C-c> <Cmd>call goda_term#ui#do_action('terminate')<CR>
nnoremap <buffer> [Space]gd <Cmd>call goda_term#ui#do_action('send', #{ str: 'git diff' })<CR>
nnoremap <buffer> [Space]gc <Cmd>call goda_term#ui#do_action('send', #{ str: 'git commit' })<CR>
nnoremap <buffer> [Space]gs <Cmd>call goda_term#ui#do_action('send', #{ str: 'git status' })<CR>
nnoremap <buffer> [Space]gA <Cmd>call goda_term#ui#do_action('send', #{ str: 'git commit --amend' })<CR>
inoremap <buffer><expr> <C-n>
      \   pum#visible()
      \ ? '<Cmd>call pum#map#insert_relative(1, "empty")<CR>'
      \ : goda_cmp#map#manual_complete(#{ sources: ['shellhistory'] })
inoremap <buffer><expr> <C-p>
      \   pum#visible()
      \ ? '<Cmd>call pum#map#insert_relative(-1, "empty")<CR>'
      \ : goda_cmp#map#manual_complete(#{ sources: ['shellhistory'] })
nnoremap <buffer> <C-r> <Cmd>Lese shellhistory<CR>
inoremap <buffer> <C-r> <Cmd>Lese shellhistory<CR>

augroup goda-term-ui-shell
  autocmd! * <buffer>
  autocmd DirChanged <buffer>
        \ : if (v:event->has_key('cwd')
        \       && t:->get('goda_term_ui_last_directory') !=# v:event.cwd)
        \ |   call goda_term#ui#do_action('cd', #{ directory: v:event.cwd })
        \ | endif
augroup END
" }}}
