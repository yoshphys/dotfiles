-- lua_add {{{
vim.keymap.set('n', "[Space]cc", "<Cmd>CodeCompanionChat Toggle<Cr>")
--- }}}

-- lua_source {{{
vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")

local writing_assistant_prompt = [[
あなたはAI執筆アシスタントである。

あなたは一般的な文章作成に関する質問に答え、以下のタスクを実行できる：
* 文章作成に関する一般的な質問への回答
* 提供された文章の構造や内容の説明
* 選択された文章の推敲・改善提案
* アイデアの整理と構造化の支援
* 文章の校正（誤字脱字、文法、表現の確認）
* 特定のトピックに関する文章の草案作成
* 文章の要約や要点整理
* 文体や語調の調整提案
* 読者層に応じた文章の最適化

ユーザーの要求には注意を払い、正確に従え。
ユーザーが提供するコンテキストや添付資料を活用せよ。
回答は簡潔で客観性に保ち、特にユーザーのコンテキストが中核タスクの範囲外の場合は無視して構わない。

すべての回答は日本語で記述せよ。
回答にはMarkdown形式を使用せよ。
H1やH2のMarkdownヘッダーは使用を禁ずる。


文章の修正や新しいコンテンツを提案する際は、以下の形式を使用せよ：

【修正前】
元の文章をここに記載

【修正後】
修正した文章をここに記載


または、新規作成の文章を提案する際は、以下の形式を使用せよ：

【提案文章】
新しく作成した文章をここに記載


タスクを与えられた場合：
1. ステップバイステップで考え、ユーザーが特に要求しない限り、またはタスクが非常に単純でない限り、計画を箇条書きで説明せよ。
2. 文章を出力する際は、関連する内容のみを含め、繰り返しや無関係な内容を避けよ。
3. 回答の最後に、会話を継続するための短い提案や次のステップを提示せよ。
]]

require("codecompanion").setup({
  opts = {
    language = "Japanese",
  },
  display = {
    chat = {
      show_header_separator = true,
    },
  },
  strategies = {
    chat = {
      adapter = "copilot",
    },
    inline = {
      adapter = "copilot",
    },
  },
  adapters = {
    acp = {
      claude_code = function()
        return require("codecompanion.adapters").extend("claude_code", {
          env = {
            CLAUDE_CODE_OAUTH_TOKEN = os.getenv("CLAUDE_CODE_OAUTH_TOKEN"),
          },
        })
      end,
      gemini_cli = function()
        return require("codecompanion.adapters").extend("gemini_cli", {
          defaults = {
            auth_method = "gemini-api-key", -- "oauth-personal"|"gemini-api-key"|"vertex-ai"
          },
          env = {
            GEMINI_API_KEY = os.getenv("GEMINI_API_KEY"),
          },
        })
      end,
    },
    http = {
      -- opts = {
      --   show_defaults = false -- hide undefined adapters i.e. openai, etc.
      -- },
      copilot = function()
        return require("codecompanion.adapters.http").extend("copilot", {
          schema = {
            model = {
              default = "gpt-5"
            }
          }
        })
      end,
    },
  },
  prompt_library = {
    ["Writing Assistant"] = {
      strategy = "chat",
      description = "A prompt for writing support",
      opts = {
        adapter = {
          name = "gemini_cli",
        },
        ignore_system_prompt = true,
      },
      prompts = {
        {
          -- role = "system", -- It seems CodeCompanion doesn't send system prompt via ACP
          role = "user",
          content = writing_assistant_prompt,
        },
      },
    },
  },
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = nil,
        -- save_chat_keymap = "",
        auto_save = true,
        expiration_days = 180,
        picker = "default",
        auto_generate_title = true,
        summary = {
          create_summary_keymap = nil,
          browse_summaries_keymap = nil,
        },
      },
    },
  },
})

--------------------------------------------------
-- CodeCompanion History -------------------------
--------------------------------------------------

vim.api.nvim_create_user_command("CodeCompanionSummarize", function()
  local history = require("codecompanion._extensions.history")
  local chat_module = require("codecompanion.strategies.chat")
  local bufnr = vim.api.nvim_get_current_buf()
  local chat = chat_module.buf_get_chat(bufnr)
  if not chat then
    vim.notify("Current buffer is not a CodeCompanion chat", vim.log.levels.WARN)
    return
  end
  history.exports.generate_summary(chat)
end, {
  desc = "Open saved summaries",
})

--------------------------------------------------
-- fidget spinner --------------------------------
--------------------------------------------------

local progress = require("fidget.progress")

local fidget_spinner = {}

function fidget_spinner:init()
  local group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", {})

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequestStarted",
    group = group,
    callback = function(request)
      local handle = fidget_spinner:create_progress_handle(request)
      fidget_spinner:store_progress_handle(request.data.id, handle)
    end,
  })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequestFinished",
    group = group,
    callback = function(request)
      local handle = fidget_spinner:pop_progress_handle(request.data.id)
      if handle then
        fidget_spinner:report_exit_status(handle, request)
        handle:finish()
      end
    end,
  })
end

fidget_spinner.handles = {}

function fidget_spinner:store_progress_handle(id, handle)
  fidget_spinner.handles[id] = handle
end

function fidget_spinner:pop_progress_handle(id)
  local handle = fidget_spinner.handles[id]
  fidget_spinner.handles[id] = nil
  return handle
end

function fidget_spinner:create_progress_handle(request)
  return progress.handle.create({
    title = " Requesting assistance (" .. request.data.strategy .. ")",
    message = "In progress...",
    lsp_client = {
      name = fidget_spinner:llm_role_title(request.data.adapter),
    },
  })
end

function fidget_spinner:llm_role_title(adapter)
  local parts = {}
  table.insert(parts, adapter.formatted_name)
  if adapter.model and adapter.model ~= "" then
    table.insert(parts, "(" .. adapter.model .. ")")
  end
  return table.concat(parts, " ")
end

function fidget_spinner:report_exit_status(handle, request)
  if request.data.status == "success" then
    handle.message = "Completed"
  elseif request.data.status == "error" then
    handle.message = " Error"
  else
    handle.message = "󰜺 Cancelled"
  end
end

fidget_spinner:init()
--- }}}
