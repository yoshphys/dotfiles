{ ... }: {
  home.stateVersion = "24.11";
  xdg.enable = true;
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
