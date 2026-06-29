{ inputs }:
let
  inherit (inputs) nix-darwin home-manager nix-monitored;

  system = "aarch64-darwin";
  username = "yosh";

  brewCasks = builtins.map (x: {name = x; greedy = true;}) (import ./brewCasks.nix);
  brewTaps = [
  ];
  brewFormulas = [ 
  ];
in
nix-darwin.lib.darwinSystem {
  modules = [
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.neovim-overlay.overlays.default # Comment out this line if neovim-overlay gets problems.
        inputs.fenix.overlays.default
        (final: prev: {
          yaskkserv2 = prev.callPackage ../../pkgs/yaskkserv2 { };
          kakehashi = prev.callPackage ../../pkgs/kakehashi { };
          zk-lsp = prev.callPackage ../../pkgs/zk-lsp { };
        })
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
          ../../home-manager/programs/yaskkserv2.nix
          ../../home-manager/programs/julia.nix
        ];

        services.yaskkserv2.enable = true;

        home.packages = (import ./packages.nix { inherit pkgs; }) ++ [
          # inputs.neovim-overlay.packages.${system}.default # Comment out this line if neovim-overlay does NOT get problems.
        ];
      };
    }
  ];
}
