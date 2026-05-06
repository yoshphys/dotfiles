import {
  type ActionArguments,
  ActionFlags,
  type DduOptions,
} from "jsr:@shougo/ddu-vim/types";
import { BaseConfig, type ConfigArguments } from "jsr:@shougo/ddu-vim/config";
import { type ActionData as FileAction } from "jsr:@shougo/ddu-kind-file";
import { type Params as FfParams } from "jsr:@shougo/ddu-ui-ff";
import { type Params as FilerParams } from "jsr:@shougo/ddu-ui-filer";

import type { Denops } from "jsr:@denops/std";
import * as fn from "jsr:@denops/std/function";
import * as stdpath from "jsr:@std/path";
import * as u from "jsr:@core/unknownutil";
import type { ActionData as GitStatusActionData } from "jsr:@kuuote/ddu-kind-git-status";


type Params = Record<string, unknown>;

type DppAction = {
  path: string;
  __name: string;
};

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    args.contextBuilder.patchGlobal({
      ui: "ff",
      profile: false,
      converterCache: true,
      matcherConcurrency: 4,
      uiOptions: {
        _: {
          filterInputFunc: "cmdline#input",
          filterInputOptsFunc: "cmdline#input_opts",
        },
        ff: {
          actions: {
            kensaku: async (args: {
              denops: Denops;
              options: DduOptions;
            }) => {
              await args.denops.dispatcher.updateOptions(
                args.options.name,
                {
                  sourceOptions: {
                    _: {
                      matchers: ["matcher_kensaku"],
                    },
                  },
                },
              );
              await args.denops.cmd("echomsg 'change to kensaku matcher'");

              return ActionFlags.Persist;
            },
          },
          filterPrompt: "❯ ",
        },
        filer: {
          toggle: true,
        },
      },
      uiParams: {
        ff: {
          autoAction: {
            delay: 0,
            name: "preview",
          },
          cursorPos: 1,
          diplayTree: false,
          filterSplitDirection: "floating",
          floatingBorder: "rounded",
          highlights: {
            filterText: "Statement",
            floating: "Normal",
            floatingBorder: "Special",
          },
          maxHighlightItems: 50,
          onPreview: async (args: {
            denops: Denops;
            previewWinId: number;
          }) => {
            await fn.win_execute(args.denops, args.previewWinId, "normal! zz");
            await fn.win_execute(args.denops, args.previewWinId, "setlocal wrap");
          },
          previewFloating: true,
          previewFloatingBorder: "single",
          previewSplit: "vertical",
          split: "floating",
          startAutoAction: true,
        } as Partial<FfParams>,
        filer: {
          autoAction: {
            name: "preview",
          },
          floatingBorder: "rounded",
          onPreview: async (args: {
            denops: Denops;
            previewWinId: number;
          }) => {
            await fn.win_execute(args.denops, args.previewWinId, "setlocal wrap");
          },
          previewFloating: true,
          previewFloatingBorder: "single",
          previewSplit: "vertical",
          sort: "natural",
          sortTreesFirst: true,
          split: "floating",
          // startAutoAction: true,
          toggle: true,
        } as Partial<FilerParams>,
      },
      sourceOptions: {
        _: {
          ignoreCase: true,
          // matchers: ["matcher_substring"],
          matchers: ["matcher_fzf"],
          sorters: ["sorter_fzf"],
          smartCase: true,
        },
        file_rec: {
          matchers: [
            "matcher_fzf",
            // "matcher_substring",
            "matcher_hidden",
          ],
          sorters: ["sorter_mtime"],
          converters: [
            "converter_hl_dir",
          ],
          columns: ["icon_filename"],
        },
        file: {
          matchers: [
            "matcher_fzf",
            // "matcher_substring",
            "matcher_hidden",
          ],
          sorters: [
            "sorter_fzf",
            // "sorter_alpha",
          ],
          converters: [
            "converter_hl_dir",
          ],
          columns: ["icon_filename"],
        },
        git_status: {
          sorters: ["sorter_alpha"],
          converters: [
            "converter_hl_dir",
            "converter_git_status"
          ]
        },
        dpp: {
          defaultAction: "cd",
          actions: {
            update: async (args: ActionArguments<Params>) => {
              const names = args.items.map((item) =>
                (item.action as DppAction).__name
              );

              await args.denops.call(
                "dpp#async_ext_action",
                "installer",
                "update",
                { names },
              );

              return Promise.resolve(ActionFlags.None);
            },
          },
        },
        line: {
          matchers: [
            "matcher_kensaku",
          ],
        },
        rg: {
          volatile: true,
          matchers: [],
          // sorters: ["sorter_mtime"],
        },
        ddt_shell_history: {
          defaultAction: "execute",
        },
        input_history: {
          defaultAction: "input",
        },
      },
      sourceParams: {
        rg: {
          args: [
            "--smart-case",
            "--column",
            "--no-heading",
            "--color",
            "never",
          ],
          minVolatileInputLength: 3,
        },
        ddt_shell_history: {
          paths: ["~/.cache/ddt-shell-history", "~/.zsh-history"]
        },
      },
      filterParams: {
        matcher_fzf: {
          highlightMatched: "PmenuMatch",
        },
        matcher_kensaku: {
          highlightMatched: "PmenuMatch",
        },
        matcher_substring: {
          highlightMatched: "PmenuMatch",
        },
        matcher_ignore_files: {
          ignoreGlobs: ["test_*.vim"],
          ignorePatterns: [],
        },
        converter_hl_dir: {
          hlGroup: ["Directory", "Keyword"],
        },
      },
      kindOptions: {
        file: {
          defaultAction: "open",
          actions: {
            grep: {
              description: "Grep from the path.",
              callback: async (args: ActionArguments<Params>) => {
                const action = args.items[0]?.action as FileAction;

                await args.denops.call("ddu#start", {
                  name: args.options.name,
                  push: true,
                  sources: [
                    {
                      name: "rg",
                      options: {
                        matchers: [],
                        volatile: true,
                      },
                      params: {
                        path: action.path,
                        input: await fn.input(args.denops, "Pattern: "),
                      },
                    },
                  ],
                });

                return Promise.resolve(ActionFlags.None);
              },
            },

            uiCd: async (args: ActionArguments<Params>) => {
              const action = args.items[0]?.action as FileAction;

              await args.denops.call("ddu#ui#do_action", {
                name: "narrow",
                params: {
                  path: action.path,
                },
              });

              return Promise.resolve(ActionFlags.None);
            },
          },
        },
        git_status: {
          actions: {
            // show diff of file
            // using https://github.com/kuuote/ddu-source-git_diff
            // example:
            //   call ddu#ui#do_action('itemAction', #{name: 'diff'})
            //   call ddu#ui#do_action('itemAction', #{name: 'diff', params: #{cached: v:true}})
            commit: async () => {
              await args.denops.call("Gin commit");
              return ActionFlags.None;
            },
            diff: async (args) => {
              const action = args.items[0].action as GitStatusActionData;
              const path = stdpath.join(action.worktree, action.path);
              await args.denops.call("ddu#start", {
                name: "file:git_diff",
                sources: [{
                  name: "git_diff",
                  options: {
                    path,
                  },
                  params: {
                    ...u.maybe(args.actionParams, u.isRecord) ?? {},
                    onlyFile: true,
                  },
                }],
              });
              return ActionFlags.None;
            },
            // fire GinPatch command to selected items
            // using https://github.com/lambdalisue/gin.vim
            patch: async (args: ActionArguments<Params>) => {
              for (const item of args.items) {
                const action = item.action as GitStatusActionData;
                await args.denops.cmd("tabnew");
                await args.denops.cmd("tcd " + action.worktree);
                await args.denops.cmd("GinPatch ++no-head " + action.path);
              }
              return ActionFlags.None;
            },
          },
          defaultAction: "open",
        },
        word: {
          defaultAction: "append",
        },
        ddt_tab: {
          defaultAction: "switch",
        },
        source: {
          defaultAction: "execute",
        },
        action: {
          defaultAction: "do",
        },
        url: {
          defaultAction: "browse",
        },
      },
      kindParams: {
        file: {
          trashCommand: ["gtrash", "put"],
        },
      },
      filterOptions: {
      _: {
          parallelSafe: true,
        },
      },
      actionOptions: {
        copy: {
          quit: false,
        },
        delete: {
          quit: false,
        },
        link: {
          quit: false,
        },
        move: {
          quit: false,
        },
        narrow: {
          quit: false,
        },
        newDirectory: {
          quit: false,
        },
        newFile: {
          quit: false,
        },
        paste: {
          quit: false,
        },
        rename: {
          quit: false,
        },
        trash: {
          quit: false,
        },
        undo: {
          quit: false,
        },
      },

    });

    args.contextBuilder.patchLocal("help", {                                                                
      uiParams: {                                                                                           
        ff: {
          onPreview: async (args: { denops: Denops; previewWinId: number }) => {                            
            await fn.win_execute(args.denops, args.previewWinId, "normal! zt");                             
            await fn.win_execute(args.denops, args.previewWinId, "setlocal wrap");
          },                                                                                                
        } as Partial<FfParams>,
      },                                                                                                    
    });             

    return Promise.resolve();
  }
}
