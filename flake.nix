{
  description = "Yosh's Nix Configurarion";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-monitored.url = "github:ners/nix-monitored";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = {
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      flake = {
        darwinConfigurations = {
          debby = import ./config/nix/hosts/debby { inherit inputs; };
        };
      };
      perSystem = { ... }: { };
    };
}
