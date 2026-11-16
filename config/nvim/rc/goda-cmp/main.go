// Command goda-cmp is the configuration of goda-cmp.vim: translated from
// the former rc/ts/ddc.ts (the Deno config of ddc.vim, now removed) and
// rc/ddc.toml's plugin list. Unlike ddc.vim, sources/filters are compiled-in
// Go packages (goda-cmp-ext) instead of separate denops plugins, so most of
// rc/ddc.toml's [[plugins]] entries have no equivalent here at all.
//
// LSP completion uses delphinus/goda-cmp-ext-luasrc.vim's "nvimlsp" source
// (asks the LSP clients Neovim already attached, via rc/lspconfig.lua's
// vim.lsp.config/enable) rather than goda-cmp-ext's own "lsp" source (which
// would start its own, separate server process per language, redundant
// with the one rc/lspconfig.lua already manages for diagnostics/hover).
//
// Dropped (no direct equivalent, or specific to the old ddc-source-lsp):
// matsui54/ddc-postfilter_score (MRU/frecency scoring; delphinus's
// sorterglobal below is a different, non-history-based kind of global
// sort) and the c/cpp-specific lsp source param tuning (enableResolveItem
// etc. don't apply to nvimlsp's own, different param set).
package main

import (
	"os"

	"github.com/Shougo/goda-cmp-ext/ext/filter/converterremoveoverlap"
	"github.com/Shougo/goda-cmp-ext/ext/filter/convertertruncateabbr"
	"github.com/Shougo/goda-cmp-ext/ext/filter/matcherhead"
	"github.com/Shougo/goda-cmp-ext/ext/filter/matcherlength"
	"github.com/Shougo/goda-cmp-ext/ext/filter/matcherprefix"
	"github.com/Shougo/goda-cmp-ext/ext/filter/sortercmdlinehistory"
	"github.com/Shougo/goda-cmp-ext/ext/filter/sorterhead"
	"github.com/Shougo/goda-cmp-ext/ext/filter/sorterrank"
	"github.com/Shougo/goda-cmp-ext/ext/filter/sortershellhistory"
	"github.com/Shougo/goda-cmp-ext/ext/source/around"
	"github.com/Shougo/goda-cmp-ext/ext/source/buffer"
	"github.com/Shougo/goda-cmp-ext/ext/source/cmdline"
	"github.com/Shougo/goda-cmp-ext/ext/source/cmdlinehistory"
	"github.com/Shougo/goda-cmp-ext/ext/source/file"
	"github.com/Shougo/goda-cmp-ext/ext/source/input"
	"github.com/Shougo/goda-cmp-ext/ext/source/line"
	"github.com/Shougo/goda-cmp-ext/ext/source/mocword"
	"github.com/Shougo/goda-cmp-ext/ext/source/register"
	"github.com/Shougo/goda-cmp-ext/ext/source/shellhistory"
	"github.com/Shougo/goda-cmp-ext/ext/source/shellnative"
	"github.com/Shougo/goda-cmp-ext/ext/ui/none"
	"github.com/Shougo/goda-cmp-ui-native.vim/ext/ui/native"
	"github.com/Shougo/goda-cmp-ui-pum.vim/ext/ui/pum"
	"github.com/Shougo/goda-cmp.vim/cmp"

	"github.com/delphinus/goda-cmp-ext-fuzzy.vim/ext/filter/matcherfuzzy"
	"github.com/delphinus/goda-cmp-ext-fuzzy.vim/ext/filter/matchernottyped"
	"github.com/delphinus/goda-cmp-ext-fuzzy.vim/ext/filter/sorterfuzzy"
	"github.com/delphinus/goda-cmp-ext-fuzzy.vim/ext/filter/sorterglobal"

	"github.com/delphinus/goda-cmp-ext-luasrc.vim/ext/source/luasrc"
)

// The shell history files, for the source and its sorter (ddc.ts's
// sourceParams.shell_history.paths).
var shellHistories = []string{"~/.cache/ddt-shell-history", "~/.zsh_history"}

func main() {
	hasMocword := os.Getenv("MOCWORD_DATA") != ""

	bridge := luasrc.NewBridge()

	b := cmp.New()
	b.AddUI(none.New())
	b.AddUI(native.New())
	b.AddUI(pum.New())

	b.AddSource(around.New(around.Params{}))
	b.AddSource(buffer.New(buffer.Params{
		RequireSameFiletype: new(false),
		LimitBytes:          50000,
		FromAltBuf:          true,
		ForceCollect:        true,
	}))
	b.AddSource(cmdline.New())
	b.AddSource(cmdlinehistory.New(cmdlinehistory.Params{}))
	b.AddSource(file.New(file.Params{FilenameChars: "[:keyword:]."}))
	b.AddSource(input.New())
	b.AddSource(line.New(line.Params{}))
	if hasMocword {
		b.AddSource(mocword.New(mocword.Params{}))
	}
	b.AddSource(register.New(register.Params{Registers: `0123456789"#:`, ExtractWords: true}))
	b.AddSource(shellhistory.New(shellhistory.Params{Paths: shellHistories}))
	b.AddSource(shellnative.New(shellnative.Params{Shell: "zsh"}))
	b.AddSource(bridge.Source("nvimlsp", luasrc.NvimLSPModule))

	b.AddFilter(converterremoveoverlap.New())
	b.AddFilter(convertertruncateabbr.New(convertertruncateabbr.Params{MaxWidth: 20}))
	b.AddFilter(matcherhead.New(matcherhead.Params{}))
	b.AddFilter(matcherprefix.New(matcherprefix.Params{}))
	b.AddFilter(matcherlength.New())
	b.AddFilter(sorterrank.New())
	b.AddFilter(sorterhead.New())
	b.AddFilter(sortercmdlinehistory.New(sortercmdlinehistory.Params{}))
	b.AddFilter(sortershellhistory.New(sortershellhistory.Params{Paths: shellHistories}))
	// delphinus/goda-cmp-ext-fuzzy.vim: fuzzy matching/sorting, and a
	// cross-source global sort (closer to blink.cmp than ddc.vim's old
	// per-source-then-concatenate order, which had no sorter active at all).
	b.AddFilter(matcherfuzzy.New())
	b.AddFilter(matchernottyped.New())
	b.AddFilter(sorterfuzzy.New())
	b.AddFilter(sorterglobal.New(map[string]int{"nvimlsp": 50}))

	commonSources := []string{"around", "file", "register"}
	var withMocword []string
	if hasMocword {
		withMocword = []string{"mocword"}
	}
	// "denippet" dropped from every Sources list below (commented, not
	// removed): denippet.vim has no goda-cmp source of its own yet, and
	// it's slated for replacement by a different snippet engine anyway.
	lspAndSnippet := append([]string{"nvimlsp" /* , "denippet" */}, commonSources...)

	b.PatchGlobal(cmp.Config{
		UI:      "pum",
		Sources: commonSources,
		CmdlineSources: map[string][]string{
			":": {"cmdline", "cmdlinehistory", "around", "register"},
			"@": {"input", "cmdlinehistory", "file", "around"},
			">": {"input", "cmdlinehistory", "file", "around"},
			"/": {"around", "line"},
			"?": {"around", "line"},
			"-": {"around", "line"},
			"=": {"input"},
		},
		AutoCompleteEvents: []string{
			"CmdlineEnter", "CmdlineChanged",
			"InsertEnter", "TextChangedI", "TextChangedP", "TextChangedT",
		},
		ContextFiletype: "treesitter",
		SourceOptions: map[string]cmp.SourceOption{
			"_": {
				IgnoreCase: new(true),
				Matchers:   []string{"matcherfuzzy", "matcherlength"},
				Sorters:    []string{"sorterfuzzy"},
				Converters: []string{"converterremoveoverlap", "convertertruncateabbr"},
				Timeout:    new(1000),
			},
			"around": {Mark: "[A]"},
			"buffer": {Mark: "[B]"},
			"cmdline": {
				IsVolatile:             new(true),
				Mark:                   "[:cmd]",
				ForceCompletionPattern: `\S/\S*|\.\w*`,
			},
			"cmdlinehistory": {Mark: "[history]"},
			// "denippet": {
			// 	Mark:                  "[snip]",
			// 	IgnoreCase:            new(false),
			// 	MinAutoCompleteLength: new(2),
			// 	Dup:                   "keep",
			// 	MaxItems:              new(10),
			// },
			"file": {
				Mark:                   "[F]",
				IsVolatile:             new(true),
				VolatilePattern:        "/",
				MinAutoCompleteLength:  new(1000),
				ForceCompletionPattern: `\S/\S*`,
			},
			"input": {
				Mark:                   "[input]",
				ForceCompletionPattern: `\S/\S*`,
				IsVolatile:             new(true),
			},
			"line": {Mark: "[line]"},
			"nvimlsp": {
				Mark:                   "[LSP]",
				ForceCompletionPattern: `\.\w*|::\w*|->\w*`,
				Dup:                    "keep",
				MaxItems:               new(5),
				IsVolatile:             new(true),
			},
			"mocword": {
				Mark:                  "[moc]",
				MinAutoCompleteLength: new(4),
				IsVolatile:            new(true),
			},
			"register": {Mark: "[reg]"},
			"shellhistory": {
				Mark:                  "[history]",
				MinAutoCompleteLength: new(3),
			},
			"shellnative": {
				Mark:                   "[sh]",
				ForceCompletionPattern: `\S/\S*`,
			},
		},
	})

	b.PatchFiletypes([]string{"latex", "typst"}, cmp.Config{
		Sources: append(append([]string{"nvimlsp" /* , "denippet" */}, commonSources...), "line"),
	})
	b.PatchFiletypes([]string{
		"markdown", "markdown_inline", "gitcommit", "comment", "text",
	}, cmp.Config{
		Sources: append(append(append([]string{}, commonSources...), "line" /* , "denippet" */), withMocword...),
	})

	// For Claude Code / the Julia REPL in nvim-aibo.
	b.PatchFiletype("aibo-prompt.aibo-tool-claude", cmp.Config{
		SpecialBufferCompletion: new(true),
		Sources:                 append(withMocword, commonSources...),
	})
	b.PatchFiletype("aibo-prompt.aibo-tool-julia", cmp.Config{
		SpecialBufferCompletion: new(true),
		Sources:                 append([]string{"nvimlsp" /* , "denippet" */}, commonSources...),
	})

	for _, ft := range []string{"html", "css"} {
		b.PatchFiletype(ft, cmp.Config{
			SourceOptions: map[string]cmp.SourceOption{
				"_": {KeywordPattern: "[0-9a-zA-Z_:#-]*"},
			},
		})
	}

	shellSourceOptions := cmp.Config{
		SpecialBufferCompletion: new(true),
		SourceOptions: map[string]cmp.SourceOption{
			"_": {KeywordPattern: "[0-9a-zA-Z_./#:-]*"},
		},
		Sources: []string{"shellnative", "shellhistory", "around"},
	}
	b.PatchFiletypes([]string{
		"zsh", "sh", "bash", "goda-term-shell", "goda-term-terminal",
	}, shellSourceOptions)

	// "#" is part of a TypeScript identifier (private class fields).
	b.PatchFiletype("typescript", cmp.Config{
		SourceOptions: map[string]cmp.SourceOption{
			"_": {KeywordPattern: `#?[a-zA-Z_][0-9a-zA-Z_]*`},
		},
	})

	b.PatchFiletypes([]string{
		"lua", "julia", "aibo-prompt.aibo-tool-julia", "aibo-prompt.aibo-tool-python",
		"python", "c", "cpp", "typescript", "nu",
	}, cmp.Config{
		Sources: lspAndSnippet,
	})

	// goda-cmp.vim and the Lua bridge, in one binary.
	b.Main(bridge)
}
