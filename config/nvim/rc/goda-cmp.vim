" hooks_file for Shougo/goda-cmp.vim, the successor of Shougo/ddc.vim:
" ported from the former rc/ddc.lua and rc/ts/ddc.ts (the Deno config, now
" replaced by rc/goda-cmp/main.go). The cmdline-completion dance
" (GodaCmpCommandlinePre/Post) follows Shougo's own goda-cmp.vim hooks_file
" (ddc#... -> goda_cmp#..., and the "User DDCCmdlineLeave" event is now
" "User GodaCmpCmdlineLeave").

" hook_add {{{
" Unset, this defaults to stdpath('config') .. '/goda-cmp' (no "rc/"),
" which isn't where ours lives (same issue as goda-term.vim/goda-pm.vim).
let g:goda_cmp#config_dir = $VIM_CONFIG_PATH .. '/rc/goda-cmp'

" Force-rebuild the Go binary from main.go, the same reason as
" :GodaPmBuild/:GodaTermBuild: every file under $VIM_CONFIG_PATH is
" deployed read-only from the Nix store (mtime fixed at the epoch), so
" goda-cmp's own "no binary yet" auto-build can misfire; run this
" explicitly after editing rc/goda-cmp/main.go.
command! GodaCmpBuild call goda_cmp#build()

function GodaCmpCommandlinePre(mode) abort
  if 'b:prev_buffer_config'->exists()
    return
  endif
  let b:prev_buffer_config = goda_cmp#get_buffer()

  if a:mode ==# ':'
    call goda_cmp#patch_buffer(#{
          \   sourceOptions: #{
          \     _: #{ keywordPattern: '[0-9a-zA-Z_:#*/.-]*' },
          \   },
          \ })
  endif

  autocmd MyAutoCmd User GodaCmpCmdlineLeave ++once call GodaCmpCommandlinePost()
  call goda_cmp#enable_cmdline()
endfunction

function GodaCmpCommandlinePost() abort
  if 'b:prev_buffer_config'->exists()
    call goda_cmp#set_buffer(b:prev_buffer_config)
    unlet b:prev_buffer_config
  endif
endfunction

nnoremap : <Cmd>call GodaCmpCommandlinePre(':')<CR>:
nnoremap ? <Cmd>call GodaCmpCommandlinePre('/')<CR>?
xnoremap : <Cmd>call GodaCmpCommandlinePre(':')<CR>:
" }}}

" hook_source {{{
" goda-cmp uses pum.vim, so the native pum only shows up when something else
" completes. Close pum.vim then, or its insert_preview text is left behind.
autocmd MyAutoCmd CompleteChanged *
      \ : if pum#visible() | call goda_cmp#hide() | call pum#close() | endif
autocmd MyAutoCmd CmdlineLeave *
      \ : if pum#visible() | call goda_cmp#hide() | call pum#close() | endif

cnoremap <expr> <C-n>
      \   pum#visible()
      \ ? pum#map#select_relative(1)
      \ : goda_cmp#map#manual_complete()
cnoremap <expr> <C-p>
      \   pum#visible()
      \ ? pum#map#select_relative(-1)
      \ : goda_cmp#map#manual_complete()

inoremap <expr> <C-y> pum#visible() ? pum#map#confirm() : '<C-y>'
cnoremap <expr> <C-y> pum#visible() ? pum#map#confirm() : '<C-y>'

function s:cancel_completion() abort
  if !pum#visible()
    return v:false
  endif
  call goda_cmp#hide()
  call pum#close()
  return v:true
endfunction
inoremap <expr><nowait> <C-g> s:cancel_completion() ? '' : '<C-g>'
cnoremap <expr><nowait> <C-g> s:cancel_completion() ? '' : '<C-g>'

call pum#set_option(#{
      \   preview: v:true,
      \   previewer: 'goda_cmp#get_previewer',
      \ })

call goda_cmp#enable_terminal()

if mode() ==# 'c' && getcmdtype() ==# ':'
  call goda_cmp#enable_cmdline()
endif

call goda_cmp#enable()
" }}}
