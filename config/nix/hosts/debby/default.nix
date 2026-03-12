{ inputs }:
let
  inherit (inputs) nix-darwin home-manager nix-monitored;

  system = "aarch64-darwin";
  username = "yosh";

  brewCasks = builtins.map (x: {name = x; greedy = true;}) (import ./brewCasks.nix);
in
nix-darwin.lib.darwinSystem {
  modules = [
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.neovim-overlay.overlays.default
        inputs.rust-overlay.overlays.default
      ];
    }
    home-manager.darwinModules.home-manager
    (import ../../nix-darwin { inherit system username brewCasks nix-monitored; })
    {
      home-manager.useGlobalPkgs = true;
      home-manager.backupFileExtension = "bk.nix";
      home-manager.users.${username} = { pkgs, ... }: {
        imports = [
          ../../home-manager/base.nix
        ];

        home.packages = import ./packages.nix { inherit pkgs; };
      };
    }
  ];
}
