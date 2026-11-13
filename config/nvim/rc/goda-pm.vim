" goda-pm.vim bootstrap. This is sourced by both Vim and Neovim (from
" rc/vimrc), so it must stay vimscript rather than Lua; see Shougo's own
" vim/rc/goda-pm.vim for the reference this is adapted from.

let s:cache_path = (has('nvim') ? stdpath('cache') : expand('~/.cache/vim')) .. '/goda-pm'
if !s:cache_path->isdirectory()
  call mkdir(s:cache_path, 'p')
endif
let $GODA_PM_CACHE_PATH = s:cache_path

" Needed here (not just in neovim.rc.lua) because this file uses the group
" below, before neovim.rc.lua is sourced via InlineVimrcs during load_state.
augroup MyAutoCmd
  autocmd!
augroup END

function! s:goda_pm_init_plugin(plugin) abort
  let dir = s:cache_path .. '/repos/github.com/' .. a:plugin
  if !dir->isdirectory()
    call system('git clone ' .. ('https://github.com/' .. a:plugin)->shellescape()
          \ .. ' ' .. dir->shellescape())
  endif
  execute 'set runtimepath^=' .. dir->fnameescape()
endfunction

call s:goda_pm_init_plugin('Shougo/goda-pm.vim')
" goda.vim's goda#register() is needed by goda_pm.vim itself whenever it
" talks to the Go binary (make_state/install/update), not just on a cold
" bootstrap, so it must always be on runtimepath, unlike goda-pm-ext-lazy.vim
" (which is loaded eagerly from the generated state once it exists).
call s:goda_pm_init_plugin('Shougo/goda.vim')

let g:goda_pm#config_dir = $VIM_CONFIG_PATH .. '/rc/goda-pm'

let s:load_state_failed = s:cache_path->goda_pm#min#load_state()

" Clear the state automatically when the Nvim/Vim version or build changes
" (after load_state, so goda-pm is already initialized): under Nix, the
" editor's build (its /nix/store path, in v:progpath) changes often, and
" loading a state built for a different build can fail to load some
" plugins (ddc failing this way leaves the cmdline unusable), so this must
" catch a build change as reliably for Vim as for Neovim.
function! s:detect_version() abort
  if has('nvim')
    " "NVIM v0.13.0-nightly+7f85c2f": the commit hash makes this precise
    " enough to catch a Nix rebuild even without a version bump.
    return execute('version')->matchstr('NVIM\s\+\zs\S\+')
  else
    " v:version alone is only major.minor (e.g. "901") and stays the same
    " across Vim patch releases, so a Nix rebuild could slip through;
    " v:versionlong adds the patch level.
    return v:versionlong->string()
  endif
endfunction

let s:version_file = s:cache_path .. '/version'
let s:current_version = s:detect_version()
let s:current_progpath = v:progpath
let s:version_changed = v:false
let s:stored_version = ''
let s:stored_progpath = ''
if s:version_file->filereadable()
  let [s:stored_version, s:stored_progpath] = s:version_file->readfile()
  let s:version_changed = s:stored_version !=# s:current_version
        \ || s:stored_progpath !=# s:current_progpath
endif
call writefile([s:current_version, s:current_progpath], s:version_file)

if s:load_state_failed || s:version_changed
  if s:version_changed
    call goda_pm#clear_state()
  endif
  call s:goda_pm_init_plugin('Shougo/goda-pm-ext-lazy.vim')

  if !s:version_changed
    let s:reason = 'state not found or invalid'
  elseif s:stored_version !=# s:current_version
    let s:reason = printf('version: %s -> %s', s:stored_version, s:current_version)
  else
    let s:reason = printf('build changed (same %s)', s:current_version)
  endif
  let s:warn_msg = printf("goda-pm: load_state failed (%s)\nexe: %s",
        \ s:reason, s:current_progpath)

  autocmd MyAutoCmd User VimEnter ++once
        \ : echohl WarningMsg
        \ | echomsg s:warn_msg
        \ | echohl NONE
        \ | call goda_pm#make_state(s:cache_path)
endif

autocmd MyAutoCmd User GodaPm:makeStatePost
      \ : echomsg 'goda-pm make_state() is done'

filetype indent plugin on

" clear (for debug)
command! GodaPmClearState call goda_pm#clear_state()

" make state (for debug)
command! GodaPmMakeState call goda_pm#make_state(s:cache_path)

" Force-rebuild the Go binary from main.go. goda-pm.vim normally rebuilds
" automatically when main.go is newer than the cached binary, but every
" file under $VIM_CONFIG_PATH is deployed read-only from the Nix store
" (mtime fixed at the epoch), so that staleness check never fires here;
" run this explicitly after editing rc/goda-pm/main.go.
command! GodaPmBuild call goda_pm#build()

" NOTE: GodaPmInstall/GodaPmUpdate are defined in goda.toml's
" "Shougo/goda-pm.vim" entry's lua_add hook, not here.
