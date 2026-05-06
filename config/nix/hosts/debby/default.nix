{ inputs }:
let
  inherit (inputs) nix-darwin home-manager nix-monitored;

  system = "aarch64-darwin";
  username = "yosh";

  brewCasks = builtins.map (x: {name = x; greedy = true;}) (import ./brewCasks.nix);
  brewTaps = [
    {
      name = "pxwg/zk-lsp";
      clone_target = "https://github.com/pxwg/zk-lsp.typst";
    }
  ];
  brewFormulas = [ "zk-lsp" ];
in
nix-darwin.lib.darwinSystem {
  modules = [
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.neovim-overlay.overlays.default # Comment out this line if neovim-overlay gets problems.
        inputs.fenix.overlays.default
        # inputs.hf-nix.overlays.default
      ];
    }
    home-manager.darwinModules.home-manager
    (import ../../nix-darwin { inherit system username brewCasks brewTaps brewFormulas nix-monitored; })
    {
      home-manager.useGlobalPkgs = true;
      home-manager.backupFileExtension = "bk.nix";
      home-manager.users.${username} = { pkgs, ... }: {
        imports = [
          ../../home-manager/base.nix
          ../../home-manager/programs/nushell.nix
          ../../home-manager/programs/nvim.nix
        ];

        home.packages = (import ./packages.nix { inherit pkgs; }) ++ [
          # inputs.neovim-overlay.packages.${system}.default # Comment out this line if neovim-overlay does NOT get problems.
        ];
      };
    }
  ];
}
