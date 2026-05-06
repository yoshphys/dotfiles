{ lib, pkgs, ... }:
let
  withNushell = [
    "atuin" # history search
    "carapace" # completer
    "dircolors" # rich colors
    "direnv"
    "keychain"
    "lazygit"
    "starship" # prompt
    "television" # fuzzy finder
    "zoxide" # directory jump
  ];
in {
  programs = lib.genAttrs withNushell (_: {                                                                                                      
    enable = true;
    enableNushellIntegration = true;                                                                                                             
  }) // {       
    nushell = {
      enable = true;
      configFile.source = ../../../nushell/config.nu;
      envFile.source = ../../../nushell/env.nu;
    };
  };
}

