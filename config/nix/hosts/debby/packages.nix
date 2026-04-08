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
  uv # python package manager
  python313 # for ROOT. Check python version by executing `root-config --python3-version`
  nodejs_24
  (pkgs.symlinkJoin {
    name = "deno-no-dx";
    paths = [ pkgs.deno ];
    postBuild = "rm $out/bin/dx";
  })
  (pkgs.fenix.combine [
    pkgs.fenix.stable.defaultToolchain
    pkgs.fenix.targets.wasm32-unknown-unknown.stable.rust-std
  ])

  # web ############################################
  dioxus-cli

  # productivity ###################################
  typst
  marp-cli
  pandoc
  pdf2svg
  yj # enable shell parsing yaml

  # science/technology #############################
  root
  gnuplot

  # audio/video ####################################
  ffmpeg-full

  # AI #############################################
  gemini-cli
  claude-code
  github-copilot-cli

  # editor #########################################
  vim-startuptime
  neovim

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
