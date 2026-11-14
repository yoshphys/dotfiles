// Command goda-term is the configuration of goda-term.vim: translated from
// the ddt.ts of this repo's former ddt.vim setup (rc/ts/ddt.ts, now removed).
package main

import (
	"fmt"
	"runtime"

	"github.com/Shougo/goda-term-ui-shell.vim/ext/ui/shell"
	"github.com/Shougo/goda-term-ui-terminal.vim/ext/ui/terminal"
	"github.com/Shougo/goda-term.vim/term"
)

func main() {
	// Highlight group names for ANSI colors 1-15 (0/black is left at the
	// terminal's default, as with the former DDTShellFg/Bg01-15 groups;
	// see rc/goda-term.vim for the :highlight definitions).
	var fgs, bgs []string
	fgs = append(fgs, "") // 0: unused
	bgs = append(bgs, "")
	for i := 1; i <= 15; i++ {
		fgs = append(fgs, fmt.Sprintf("GodaTermFg%02d", i))
		bgs = append(bgs, fmt.Sprintf("GodaTermBg%02d", i))
	}

	// zsh's prompt symbol is "❯", not the usual "%".
	promptPattern := `\w*❯ \?`
	if runtime.GOOS == "windows" {
		promptPattern = `\f\+>`
	}

	b := term.New()
	b.AddUI(shell.New())
	b.AddUI(terminal.New())
	b.PatchGlobal(term.Options{
		UIParams: map[string]term.Params{
			"shell": {
				"aliases": map[string]string{
					"ls": "ls --color",
				},
				"ansiColorHighlights": shell.ANSIColorHighlights{
					Fgs:       fgs,
					Bgs:       bgs,
					Bold:      "Bold",
					Italic:    "Italic",
					Underline: "Underlined",
				},
				"noSaveHistoryCommands": []string{"history"},
				"userPrompt":            "'| ' .. fnamemodify(getcwd(), ':~') .. MyGitStatus()",
				"shellHistoryPath":      "~/.cache/ddt-shell-history",
			},
			"terminal": {
				"command":       []string{"zsh"},
				"promptPattern": promptPattern,
			},
		},
	})
	b.Main()
}
