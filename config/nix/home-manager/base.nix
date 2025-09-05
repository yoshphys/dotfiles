{ pkgs, config, ... }: {
  home.stateVersion = "24.11";
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
