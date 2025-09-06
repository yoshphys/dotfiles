{ pkgs, ... }:
with pkgs; [
  sheldon # zsh plugin manager
  starship # prompt decoration
  eza # rich ls

  deno
  peco
  ghq
  fzf

  # AI #############################################
  gemini-cli

  # LSP/formatter ##################################
  tinymist
  basedpyright
  lua-language-server
  copilot-language-server

  # editor #########################################
  vim-startuptime
  neovim
]
