{ lib, pkgs, ... }:
let
  withNushell = [
    "atuin" # history search
    "carapace" # completer
    "dircolors" # rich colors
    "direnv"
    "keychain"
    "lazygit"
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
      # home.sessionVariables only carries values env.nu already sets by hand,
      # so loading them would just add a bash subprocess to every startup.
      loadSessionVariables = false;
    };
    starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        jobs.disabled = true;
      };
    };
  };
}

