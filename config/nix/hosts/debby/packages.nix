{ pkgs, npmPkgs, ... }:
with pkgs; [
  sheldon # zsh plugin manager
  starship # prompt decoration
  eza # rich ls
  direnv

  deno
  peco
  ghq
  fzf

  # AI #############################################
  npmPkgs."@github/copilot-language-server"
  npmPkgs."@google/gemini-cli"

  # LSP/formatter ##################################
  tinymist
  basedpyright
  lua-language-server
  # copilot-language-server

  # editor #########################################
  vim-startuptime
  neovim
]
