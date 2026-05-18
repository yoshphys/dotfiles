# Dotfiles Structure

## Entry points
- `flake.nix` — Nix flake (home-manager + nix-darwin)
- `Makefile` — deploy/build commands

## config/nix/
- `home-manager/base.nix` — base home-manager config
- `home-manager/programs/` — per-program home-manager modules (nvim, nushell, yaskkserv2)
- `hosts/debby/` — host-specific config (Mac: default.nix, packages.nix, brewCasks.nix)
- `nix-darwin/default.nix` — system-level nix-darwin config
- `pkgs/yaskkserv2/` — custom Nix package for yaskkserv2

## config/nvim/
- `init.lua` — entry point
- `rc/dpp.lua` — dpp plugin manager bootstrap
- `rc/toml/` — plugin definitions (dpp/ddc/ddu/ddt/lazy/startup)
- `rc/ts/` — TypeScript plugin configs (dpp/ddc/ddu/ddt)
- `rc/hooks/` — per-plugin hook configs (lspconfig, ddc, ddu, ddt, ddu-ui-*)
- `rc/vimrc.lua` — general keymaps/options
- `denops/@lspoints/config.ts` — lspoints (LSP client) config
- `snippets/global.ts` — global snippets

## config/nushell/
- `config.nu`, `env.nu`

## config/scripts/
- `make-yaskkserv2-dict.nu` — script to generate yaskkserv2 dictionary
