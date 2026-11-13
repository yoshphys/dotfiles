# Dotfiles Structure

## Entry points
- `flake.nix` — Nix flake (home-manager + nix-darwin)
- `Makefile` — deploy/build commands

## config/nix/
- `home-manager/base.nix` — base home-manager config
- `home-manager/programs/` — per-program home-manager modules (nvim, nushell, edit-in-app, julia)
- `hosts/debby/` — host-specific config (Mac: default.nix, packages.nix, brewCasks.nix)
- `nix-darwin/default.nix` — system-level nix-darwin config
- `pkgs/` — custom Nix packages (edit-in-app, editprompt, kakehashi, tanim-cli, zk-lsp)

## config/nvim/
- `init.lua` — entry point
- `rc/vimrc.lua` — sources `rc/goda-pm.lua`
- `rc/goda-pm.lua` — goda-pm.vim plugin manager bootstrap
- `rc/goda-pm/main.go` — goda-pm.vim config (Go module): loads the TOML files below, sets up InlineVimrcs
- `rc/merge.toml`, `rc/lazy.toml`, `rc/ddc.toml`, `rc/ddu.toml`, `rc/goda.toml`, `rc/neovim.toml` — plugin definitions, by load strategy
- `rc/*.lua` (`ddc.lua`, `ddt.lua`, `ddu.lua`, `ddu-ui-ff.lua`, `ddu-ui-filer.lua`, `lspconfig.lua`) — per-plugin hook configs, referenced by `hooks_file` in the TOML files above
- `rc/ts/` — TypeScript plugin configs for the denops-based ddc/ddu/ddt plugins
- `rc/options.rc.vim` — vim/neovim-common options and mappings (InlineVimrc, plain vimscript)
- `rc/neovim.rc.lua` — neovim-only options, keymaps and autocmds (InlineVimrc)
- `rc/unix.rc.vim` — Unix-only settings (InlineVimrc)
- `denops/@lspoints/config.ts` — lspoints (LSP client) config
- `snippets/global.ts` — global snippets

## config/nushell/
- `config.nu`, `env.nu`
