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

  # nix ############################################
  nix-tree

  # git ############################################
  gh # github cli
  ghq
  lazygit

  # programming ####################################
  python313 # for ROOT. Check python version by executing `root-config --python3-version`
  nodejs_24
  deno
  rust-bin.stable.latest.default

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
  claude-code
  github-copilot-cli

  # editor #########################################
  vim-startuptime
  neovim

  # LSP/formatter ##################################
  tinymist
  basedpyright
  lua-language-server
  copilot-language-server

  # renderer #######################################
  # povray

  # brewCasks ######################################
  # I decided not to use brewCasks of brew-nix. I use brewCasks in nix-darwin instead.
  # brewCasks.ghostty
]
