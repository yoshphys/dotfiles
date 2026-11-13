"---------------------------------------------------------------------------
" For CUI:
"

if !has('gui_running')
  " Disable the mouse. Toggle with the mouse keymap in neovim.rc.lua.
  set mouse=
endif

if !has('nvim')
  " Enable 256 color terminal.
  set t_Co=256

  set term=xterm-256color

  " Change cursor shape.
  let &t_SI = "\e[6 q"
  let &t_SR = "\e[4 q"
  let &t_EI = "\e[0 q"

  " Change cursor color.
  let &t_SC = "\e]12;"
  let &t_EC = "\x07"
endif
