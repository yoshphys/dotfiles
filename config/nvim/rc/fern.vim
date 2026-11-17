" hooks_file for lambdalisue/vim-fern, a file explorer; the eventual
" successor of ddu.vim's filer use case (Shougo/ddu-source-file(_rec) +
" Shougo/ddu-ui-filer, see rc/ddu-ui-filer.lua). Sibling plugins registered
" via on_source in rc/lazy.toml: vim-fern-hijack (netrw replacement, loaded
" eagerly instead, see its own entry), vim-nerdfont + vim-fern-renderer-
" nerdfont (icons), vim-fern-git-status + vim-fern-mapping-git (git status
" badge / stage-unstage mappings on file:// nodes).

" hook_add {{{
" [Space]f: open fern as a floating window pinned to the right edge of the
" window that was current when invoked (its "anchor"). Opening a file from
" inside it closes the float and edits the file in the anchor window
" instead of replacing the float's own buffer; see s:fern_float_open_expr
" below. Plain Vim has no equivalent floating-window API (popup_create() is
" a wholly different mechanism), so fall back to a plain right-side
" vertical drawer there.
function FernFloat() abort
  if !has('nvim')
    execute 'Fern' fnameescape(getcwd()) '-drawer -right'
    return
  endif

  let anchor = win_getid()
  let width = max([10, min([40, winwidth(anchor) - 10])])
  let buf = nvim_create_buf(v:false, v:true)
  let win = nvim_open_win(buf, v:true, #{
        \   relative: 'win',
        \   win: anchor,
        \   anchor: 'NE',
        \   row: 0,
        \   col: winwidth(anchor),
        \   width: width,
        \   height: winheight(anchor),
        \   border: 'rounded',
        \   style: 'minimal',
        \ })
  call setwinvar(win, 'fern_float_anchor', anchor)
  execute 'Fern' fnameescape(getcwd()) '-opener=edit'
endfunction

nnoremap [Space]f <Cmd>call FernFloat()<CR>
" }}}

" hook_source {{{
let g:fern#hide_cursorline = 1

" Only takes effect inside a fern buffer opened by FernFloat() above (that
" function tags the floating window itself with w:fern_float_anchor, which
" -- being window-local, not buffer-local -- survives fern replacing the
" window's scratch buffer with its own fern:// one).
function s:init_fern_float() abort
  if !exists('w:fern_float_anchor')
    return
  endif
  nnoremap <buffer> q <Cmd>call nvim_win_close(win_getid(), v:true)<CR>
  nnoremap <buffer><expr> <CR> <SID>fern_float_open_expr('edit')
  nnoremap <buffer><expr> e    <SID>fern_float_open_expr('edit')
  nnoremap <buffer><expr> l    <SID>fern_float_open_expr('edit')
  nnoremap <buffer><expr> s    <SID>fern_float_open_expr('split')
  nnoremap <buffer><expr> v    <SID>fern_float_open_expr('vsplit')
  nnoremap <buffer><expr> t    <SID>fern_float_open_expr('tabedit')
endfunction

" {open_cmd}: how to open a leaf node in the anchor window. A branch node
" just expands/collapses in place; the floating window stays open.
function s:fern_float_open_expr(open_cmd) abort
  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  if node is# v:null
    return "\<Nop>"
  endif
  if node.status isnot# helper.STATUS_NONE
    return node.status is# helper.STATUS_COLLAPSED
          \ ? "\<Plug>(fern-action-expand)"
          \ : "\<Plug>(fern-action-collapse)"
  endif
  let anchor = w:fern_float_anchor
  let bufname = node.bufname
  call nvim_win_close(win_getid(), v:true)
  call win_gotoid(anchor)
  execute a:open_cmd fnameescape(bufname)
  return ''
endfunction

augroup fern-float
  autocmd! *
  autocmd FileType fern call s:init_fern_float()
augroup END
" }}}
