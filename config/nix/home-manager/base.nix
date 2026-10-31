{ ... }: {
  home.stateVersion = "26.11";
  xdg.enable = true;
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
