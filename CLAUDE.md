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
- `rc/vimrc` — common entry (vim/neovim), sources `rc/goda-pm.vim`
- `rc/goda-pm.vim` — goda-pm.vim plugin manager bootstrap (vimscript: shared by vim/neovim)
- `rc/goda-pm/main.go` — goda-pm.vim config (Go module): loads the TOML files below, sets up InlineVimrcs
- `rc/goda-term/main.go` — goda-term.vim config (Go module, the successor of ddt.vim; registered in `rc/goda.toml`)
- `rc/goda-cmp/main.go` — goda-cmp.vim config (Go module, the successor of ddc.vim; registered in `rc/goda.toml`). Sources/filters are compiled-in Go packages (goda-cmp-ext and others), not separate plugins; LSP completion uses the `nvimlsp` bridge source (the LSP clients Neovim already attached, not a separate server)
- `rc/merge.toml`, `rc/lazy.toml`, `rc/ddu.toml`, `rc/goda.toml`, `rc/neovim.toml` — plugin definitions, by load strategy
- `rc/*.lua` (`ddu.lua`, `ddu-ui-ff.lua`, `ddu-ui-filer.lua`, `lspconfig.lua`) / `rc/goda-term.vim` / `rc/goda-cmp.vim` / `rc/fern.vim` — per-plugin hook configs, referenced by `hooks_file` in the TOML files above
- `rc/fern.vim` — lambdalisue/vim-fern config (file explorer, gradually replacing ddu.vim's filer use case); `[Space]f` opens it as a floating window anchored to the current window
- `rc/lese/custom.lua` — lambdalisue/vim-lese's picker declarations (fuzzy finder, gradually replacing ddu.vim's `ddu-ui-ff` use case); a copy of lese's own bundled defaults plus a "register" picker lese ships no source for. lese's own keymaps (`;h`/`;H`/`;r`/`;R`; only these four are migrated so far, the rest still lives in `rc/ddu.lua`) are inlined directly in `rc/lazy.toml`, not a separate hooks_file
- `rc/ts/` — TypeScript plugin configs for the denops-based ddu plugins
- `rc/options.rc.vim` — vim/neovim-common options and mappings (InlineVimrc, plain vimscript)
- `rc/neovim.rc.lua` — neovim-only options, keymaps and autocmds (InlineVimrc)
- `rc/unix.rc.vim` — Unix-only settings (InlineVimrc)
- `rc/ft.vim` — plugin-independent per-filetype settings (merge.toml's file-level `hooks_file`, parsed into `[ftplugin]` entries)
- `snippets/global.ts` — global snippets (loaded by denippet.vim)

## config/nushell/
- `config.nu`, `env.nu`
