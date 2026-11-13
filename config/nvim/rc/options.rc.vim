"---------------------------------------------------------------------------
" Options and mappings common to Vim and Neovim.
" NOTE: there is no separate mappings.rc.vim in this config, so shared
" mappings live here too.
"

"---------------------------------------------------------------------------
" Base:
"

language en_US.UTF-8
set ambiwidth=single

set clipboard+=unnamedplus

"---------------------------------------------------------------------------
" File:
"

set swapfile
set hidden
set backup
set backupdir=~/.vim/backups

"---------------------------------------------------------------------------
" Indent:
"

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

"---------------------------------------------------------------------------
" Cursor:
"

set cursorline
set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor25-Cursor/lCursor,t:ver25-Cursor/lCursor

"---------------------------------------------------------------------------
" Lining:
"

set number
set relativenumber
set nowrap
set sidescroll=1
set sidescrolloff=8

"---------------------------------------------------------------------------
" Menu and command:
"

set wildmenu
set cmdheight=1
set noshowmode
set laststatus=2
set showcmd

"---------------------------------------------------------------------------
" Search/replace:
"

set hlsearch
set incsearch
set matchtime=1

"---------------------------------------------------------------------------
" Appearances:
"

set termguicolors
" Disable the tab line on the top.
set showtabline=0
set signcolumn=yes:1

"---------------------------------------------------------------------------
" Misc:
"

" Used by $VIMRUNTIME/ftplugin/tex.vim.
let g:tex_flavor = 'latex'

"---------------------------------------------------------------------------
" Mapping:
"

" [Space]: Other useful commands.
" NOTE: "map" (not noremap) on purpose, so [Space]xxx mappings defined
" elsewhere keep working through this prefix.
map <Space> [Space]
xmap <Space> [Space]
nnoremap [Space] <Nop>
xnoremap [Space] <Nop>

" Cmdline: move/delete like readline.
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-d> <Delete>
