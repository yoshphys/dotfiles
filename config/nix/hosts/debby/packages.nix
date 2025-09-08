{ pkgs, ... }:
with pkgs; [
  # terminal utility ###############################
  sheldon # zsh plugin manager
  starship # prompt decoration
  bat # richer cat
  eza # richer ls
  tree
  fd
  fzf
  ripgrep
  unar # richer unzip
  peco # richer `command | grep`
  tmux

  # system #########################################
  gdu # disk capacity analyzer
  bottom # richer top
  mosh
  mutagen

  # git ############################################
  gh # github cli
  ghq
  lazygit

  # programming ####################################
  deno
  # rust # found no package
  # lua

  # productivity ###################################
  typst
  marp-cli
  pandoc
  pdf2svg

  # science/technology #############################
  root
  gnuplot

  # AI #############################################
  gemini-cli

  # editor #########################################
  vim-startuptime
  neovim

  # LSP/formatter ##################################
  tinymist
  basedpyright
  lua-language-server
  copilot-language-server

  # brewCasks ######################################
  brewCasks.inkscape
]
