{ pkgs, ... }:
with pkgs; [
  # terminal utility ###############################
  sheldon # zsh plugin manager
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
  uv # python package manager
  (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.root # for enabling cern ROOT
  ]))
  nodejs_24
  (pkgs.symlinkJoin { # to unlink `dx` command which conflicts with dioxus-cli
    name = "deno-no-dx";
    paths = [ pkgs.deno ];
    postBuild = "rm $out/bin/dx";
  })
  (pkgs.fenix.combine [
    pkgs.fenix.stable.defaultToolchain
    pkgs.fenix.targets.wasm32-unknown-unknown.stable.rust-std
  ])
  rlwrap # for CLI tools

  # web app ########################################
  dioxus-cli

  # productivity ###################################
  typst
  marp-cli
  pandoc
  pdf2svg
  yj # enable shell parsing yaml
  poppler-utils # for handling PDF

  # science/technology #############################
  root
  gnuplot

  # audio/video ####################################
  # ffmpeg

  # AI #############################################
  gemini-cli
  claude-code
  github-copilot-cli

  # editor #########################################
  vim-startuptime
  neovim # from neovim-overlay

  # LSP/formatter ##################################
  tree-sitter
  tinymist
  basedpyright
  lua-language-server
  copilot-language-server

  # brewCasks ######################################
  # I decided not to use brewCasks of brew-nix. I use brewCasks in nix-darwin instead.
  # brewCasks.ghostty
]
