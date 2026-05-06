import { BaseConfig, ConfigArguments } from "jsr:@shougo/ddc-vim/config";
import { type DdcItem } from "jsr:@shougo/ddc-vim/types";

import type { Denops } from "jsr:@denops/std";
import * as fn from "jsr:@denops/std/function";

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {

    const commonSources = [
      "around",
      "file",
      "register"
      // "copilot",
    ];

    const mocWord = Deno.env.get("MOCWORD_DATA") ? ["mocword"] : [];

    args.contextBuilder.patchGlobal({
      ui: "pum",
      // ui: "native",
      // ui: "none",
      matcherConcurrency: 4,
      // dynamicUi: async (denops: Denops, args: Record<string, unknown>) => {
      //   const uiArgs = args as {
      //     items: DdcItem[];
      //   };
      //   const mode = await fn.mode(denops);
      //   return Promise.resolve(
      //     mode !== "t" && uiArgs.items.length == 1 ? "inline" : "pum",
      //   );
      // },
      dynamicSources: async (denops: Denops, args: Record<string, unknown>) => {
        const sourceArgs = args as {
          context: Context;
          sources: string[];
        };
        const mode = await fn.mode(denops);
        return Promise.resolve(
          mode === "c" && await fn.getcmdtype(denops) === ":"
            ? ["shell_native", ...sourceArgs.sources]
            : null,
        );
      },
      autoCompleteEvents: [
        "CmdlineEnter",
        "CmdlineChanged",
        "InsertEnter",
        "TextChangedI",
        "TextChangedP",
        "TextChangedT",
      ],
      sources: commonSources,
      cmdlineSources: {
        ":": [
          "cmdline",
          "cmdline_history",
          "around",
          "register",
        ],
        "@": [
          "input",
          "cmdline_history",
          "file",
          "around",
        ],
        ">": [
          "input",
          "cmdline_history",
          "file",
          "around",
        ],
        "/": [
          "around",
          "line",
        ],
        "?": [
          "around",
          "line",
        ],
        "-": [
          "around",
          "line",
        ],
        "=": [
          "input",
        ],
      },
      sourceOptions: {
        _: {
          ignoreCase: true,
          matchers: [
            "matcher_fuzzy",
            // "matcher_head",
            // "matcher_prefix",
            "matcher_length",
          ],
          sorters: [
            // "sorter_fuzzy",
            // "sorter_rank",
          ],
          converters: [
            "converter_remove_overlap",
            // "converter_fuzzy",
            "converter_truncate_abbr",
          ],
          timeout: 1000,
        },
        around: {
          mark: "[A]",
        },
        buffer: {
          mark: "[B]",
        },
        cmdline: {
          isVolatile: true,
          mark: "[:cmd]",
          // matchers: [
          //   "matcher_length",
          // ],
          // sorters: [
          //   "sorter_cmdline_history",
          // ],
          forceCompletionPattern: String.raw`\S/\S*|\.\w*`,
        },
        cmdline_history: {
          mark: "[history]",
        },
        // copilot: {
        //   mark: "[AI]",
        //   matchers: [],
        //   minAutoCompleteLength: 0,
        //   isVolatile: false,
        // },
        denippet: {
          mark: "[snip]",
          ignoreCase: false,
          minAutoCompleteLength: 2,
          dup: "keep",
          maxItems: 10,
        },
        file: {
          mark: "[F]",
          isVolatile: true,
          volatilePattern: "/",
          minAutoCompleteLength: 1000,
          forceCompletionPattern: String.raw`\S/\S*`,
        },
        input: {
          mark: "[input]",
          forceCompletionPattern: String.raw`\S/\S*`,
          isVolatile: true,
        },
        line: {
          mark: "[line]",
        },
        lsp: {
          mark: "[LSP]",
          forceCompletionPattern: String.raw`\.\w*|::\w*|->\w*`,
          dup: "keep",
          maxItems: 5,
          isVolatile: true,
        },
        mocword: {
          mark: "[moc]",
          minAutoCompleteLength: 4,
          isVolatile: true,
        },
        register: {
          mark: "[reg]",
        },
        shell_history: {
          mark: "[history]",
          minAutoCompleteLength: 3,
        },
        shell_native: {
          mark: "[sh]",
          forceCompletionPattern: String.raw`\S/\S*`,
        },
        skkeleton: {
          mark: "[SKK]",
          matchers: [],
          sorters: [],
          converters: [],
          isVolatile: true,
          minAutoCompleteLength: 1,
        },
        skkeleton_okuri: {
          mark: "[SKK*]",
          matchers: [],
          sorters: [],
          converters: [],
          isVolatile: true,
        },
      },
      sourceParams: {
        buffer: {
          requireSameFiletype: false,
          limitBytes: 50000,
          fromAltBuf: true,
          forceCollect: true,
        },
        file: {
          filenameChars: "[:keyword:].",
        },
        lsp: {
          enableAdditionalTextEdit: true,
          enableDisplayDetail: true,
          enableMatchLabel: true,
          enableResolveItem: true,
          // lspEngine: "lspoints",
          // snippetEngine: async (body: string) =>
          //   await args.denops.call("denippet#anonymous", body),
          //   await args.denops.call("vsnip#anonymous", body),
        },
        register: {
          registers: '0123456789"$:"',
          extractWords: true,
        },
        shell_history: {
          paths: [
            "~/.cache/ddt-shell-history",
            "~/.zsh-history",
          ],
        },
        shell_native: {
          shell: "zsh",
        },
        // copilot: {
        //   copilot: "lua",
        // },
      },
      filterOptions: {
        _: {
          parallelSafe: true,
        },
      },
      filterParams: {
        converter_truncate_abbr: {
          maxAbbrWidth: 20,
        },
        postfilter_score: {
          excludeSources: [
            "skkeleton",
            // "copilot",
          ],
        }
      },
      postFilters: [
        "postfilter_score"
      ],
    });

    for (
      const filetype of [
        "latex",
        "typst",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sources: ["lsp", "denippet", ...commonSources, "line", ...mocWord],
      });
    }

    for (
      const filetype of [
        "markdown",
        "markdown_inline",
        "gitcommit",
        "comment",
        "text",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sources: [...commonSources, "line", ...mocWord],
      });
    }

    // for julia REPL in nvim-aibo
    args.contextBuilder.patchFiletype("aibo-prompt.aibo-tool-julia", {
      sources: ["lsp", "denippet"].concat(commonSources),
    });

    for (
      const filetype of [
        "c",
        "cpp",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sourceParams: {
          lsp: {
            enableAdditionalTextEdit: true,
            enableResolveItem: false,
            enableMatchLabel: false,
          },
        },
      });
    }

    for (const filetype of ["html", "css"]) {
      args.contextBuilder.patchFiletype(filetype, {
        sourceOptions: {
          _: {
            keywordPattern: "[0-9a-zA-Z_:#-]*",
          },
        },
      });
    }


    const shellSourceOptions = {
      specialBufferCompletion: true,
      sourceOptions: {
        _: {
          keywordPattern: "[0-9a-zA-Z_./#:-]*",
        },
      },
      sources: [
        "shell_native",
        "shell_history",
        "around",
      ],
    };
    for (
      const filetype of [
        "zsh",
        "sh",
        "bash",
        "ddt-shell",
        "ddt-terminal",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, shellSourceOptions);
    }

    // Use "#" as TypeScript keywordPattern
    for (const filetype of ["typescript"]) {
      args.contextBuilder.patchFiletype(filetype, {
        sourceOptions: {
          _: {
            keywordPattern: "#?[a-zA-Z_][0-9a-zA-Z_]*",
          },
        },
      });
    }

    for (
      const filetype of [
        "lua",
        "julia",
        "aibo-prompt.aibo-tool-julia",
        "aibo-prompt.aibo-tool-python",
        "python",
        "c",
        "cpp",
        "typescript",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sources: ["lsp", "denippet"].concat(commonSources),
      });
    }

  }
}
