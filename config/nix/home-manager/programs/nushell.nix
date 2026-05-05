{ pkgs, ... }: {
  home.packages = [ pkgs.nu_scripts ];

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.nushell = {
    enable = true;
    configFile.source = ../../../nushell/config.nu;
    envFile.source = ../../../nushell/env.nu;
    extraConfig =
      let
        completionSources = map (cmd:
          "${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${cmd}/${cmd}-completions.nu"
        ) [
          "bat"
          "btm"
          "curl"
          "eza"
          "gh"
          "git"
          "make"
          "man"
          "nix"
          "rg"
          "ssh"
          "tar"
          "typst"
          "uv"
          "zoxide"
        ];

        extraSources = [
          "${pkgs.nu_scripts}/share/nu_scripts/custom-menus/zoxide-menu.nu"
          "${pkgs.nu_scripts}/share/nu_scripts/themes/nu-themes/catppuccin-mocha.nu"
        ];

        sourceLines = map (path: "source ${path}") (completionSources ++ extraSources);
      in
      builtins.concatStringsSep "\n" sourceLines + "\n";
  };
}
