import { BaseConfig, ConfigArguments } from "jsr:@shougo/ddt-vim/config";

import * as fn from "jsr:@denops/std/function";

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
    const hasWindows = await fn.has(args.denops, "win32");
    const terminal_prompt_symbol = "❯" // usually "%" for zsh

    args.contextBuilder.patchGlobal({
      debug: false,
      nvimServer: "~/.cache/nvim/server.pipe",
      uiParams: {
        shell: {
          aliases: {
            ls: "ls --color",
          },
          ansiColorHighlights: {
            bgs: [
              "",             // 0: unused
              "DDTShellBg01", // red
              "DDTShellBg02", // green
              "DDTShellBg03", // yellow
              "DDTShellBg04", // blue
              "DDTShellBg05", // magenta → pink
              "DDTShellBg06", // cyan → sky
              "DDTShellBg07", // white → text
              "DDTShellBg08", // bright black → overlay1
              "DDTShellBg09", // bright red → maroon
              "DDTShellBg10", // bright green
              "DDTShellBg11", // bright yellow
              "DDTShellBg12", // bright blue → lavender
              "DDTShellBg13", // bright magenta → pink
              "DDTShellBg14", // bright cyan → teal
              "DDTShellBg15", // bright white → text
            ],
            bold: "Bold",
            fgs: [
              "",             // 0: unused
              "DDTShellFg01", // red
              "DDTShellFg02", // green
              "DDTShellFg03", // yellow
              "DDTShellFg04", // blue
              "DDTShellFg05", // magenta → pink
              "DDTShellFg06", // cyan → sky
              "DDTShellFg07", // white → text
              "DDTShellFg08", // bright black → overlay1
              "DDTShellFg09", // bright red → maroon
              "DDTShellFg10", // bright green
              "DDTShellFg11", // bright yellow
              "DDTShellFg12", // bright blue → lavender
              "DDTShellFg13", // bright magenta → pink
              "DDTShellFg14", // bright cyan → teal
              "DDTShellFg15", // bright white → text
            ],
            italic: "Italic",
            underline: "Underlined",
          },
          noSaveHistoryCommands: [
            "history",
          ],
          userPrompt: "'| ' .. fnamemodify(getcwd(), ':~') .. MyGitStatus()",
          shellHistoryPath: "~/.cache/ddt-shell-history",
        },
        terminal: {
          command: ["zsh"],
          promptPattern: hasWindows ? String.raw`\f\+>` : String.raw`\w*${terminal_prompt_symbol} \?`,
        },
      },
    });
  }
}
