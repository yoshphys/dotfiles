-- lese's custom.lua: this repo's copy of lese's own bundled
-- assets/default_custom.lua (every picker it defines, verbatim) plus one
-- addition of our own, the "register" picker below -- lese ships no
-- register source, unlike the old ddu-source-register (see rc/ddu.lua's
-- commented-out ";r" mapping; this picker is what rc/lese.vim's ";R"
-- binds instead, since ";r" itself is now lese's "rg" picker).
--
-- Install https://github.com/BurntSushi/ripgrep to use 'builtin.curator.rg'
-- Install https://www.nerdfonts.com/ to use 'builtin.renderer.nerdfont'
-- Install https://github.com/thinca/vim-qfreplace to use 'Qfreplace'
--
-- See :help lese-customization-type-checking to have lua-language-server know
-- the types used below.

local builtin = require("lese.builtin")
local std = require("lese.std")
local define = require("lese.define")

local function merge(...)
  local out = {}
  for _, actions in ipairs({ ... }) do
    for name, action in pairs(actions) do
      out[name] = action
    end
  end
  return out
end

local path_actions = merge(
  builtin.action.default_open_actions,
  builtin.action.default_systemopen_actions,
  builtin.action.default_cd_actions
)

local quickfix_actions = merge(builtin.action.default_quickfix_actions, {
  ["quickfix:qfreplace"] = builtin.action.quickfix({ after = "Qfreplace" }),
})

local misc_actions = merge(
  builtin.action.default_echo_actions,
  builtin.action.default_yank_actions,
  builtin.action.default_submatch_actions
)

local EXCLUDED_FILES = {
  ".7z",
  ".DS_Store",
  ".avi",
  ".bmp",
  ".class",
  ".dll",
  ".dmg",
  ".doc",
  ".docx",
  ".dylib",
  ".ear",
  ".exe",
  ".fla",
  ".flac",
  ".flv",
  ".gif",
  ".ico",
  ".id_ed25519",
  ".id_rsa",
  ".iso",
  ".jar",
  ".jpeg",
  ".jpg",
  ".key",
  ".mkv",
  ".mov",
  ".mp3",
  ".mp4",
  ".mpeg",
  ".mpg",
  ".o",
  ".obj",
  ".ogg",
  ".pdf",
  ".png",
  ".ppt",
  ".pptx",
  ".rar",
  ".so",
  ".swf",
  ".tar.gz",
  ".war",
  ".wav",
  ".webm",
  ".wma",
  ".wmv",
  ".xls",
  ".xlsx",
  ".zip",
}

local EXCLUDED_DIRECTORIES = {
  "$RECYCLE.BIN",
  ".cache",
  ".git",
  ".hg",
  ".ssh",
  ".svn",
  "__pycache__", -- Python
  "build", -- C/C++
  "node_modules", -- Node.js
  "target", -- Rust
}

local function filter_file(path)
  for _, suffix in ipairs(EXCLUDED_FILES) do
    if path:sub(-#suffix) == suffix then
      return false
    end
  end
  return true
end

local function filter_directory(path)
  local name = path:match("([^/\\]+)[/\\]*$") or path
  for _, excluded in ipairs(EXCLUDED_DIRECTORIES) do
    if name == excluded then
      return false
    end
  end
  return true
end

local function sorters()
  return {
    builtin.sorter.noop(),
    builtin.sorter.lexical(),
    builtin.sorter.lexical({ reverse = true }),
  }
end

-- custom.source.register: enumerates every non-empty register (numbered
-- 0-9, lettered a-z, and the special "+*-:.%# registers), newest content
-- first for the numbered ones. No ordering/MRU beyond that -- unlike
-- ddu-source-register, lese has no notion of "recently used" registers.
local function register_names()
  local names = {}
  for i = 0, 9 do
    names[#names + 1] = tostring(i)
  end
  for c = string.byte("a"), string.byte("z") do
    names[#names + 1] = string.char(c)
  end
  for _, c in ipairs({ '"', "+", "*", "-", ":", ".", "%", "#" }) do
    names[#names + 1] = c
  end
  return names
end

-- Like builtin.source.buffer/oldfiles, detail only keeps what identifies
-- the register; builtin.previewer.file/buffer/helptag all re-fetch their
-- content fresh in the previewer rather than stashing it from collect, so
-- this does too (also avoids holding every listed register's content, plus
-- a 2nd copy for its previewer, for the whole picker session).
local function register_source()
  return define.source({
    name = "custom.source.register",
    collect = function(ctx)
      local fn = ctx.host.fn
      local id = 0
      for _, name in ipairs(register_names()) do
        local content = fn.getreg(name)
        if content ~= "" then
          id = id + 1
          local firstline = content:match("^[^\n]*") or content
          ctx:emit({
            id = id,
            value = string.format("[%s] %s", name, firstline),
            detail = { register = { name = name } },
          })
        end
      end
    end,
  })
end

local function register_previewer()
  return define.previewer({
    name = "custom.previewer.register",
    preview = function(ctx, params)
      local fn = ctx.host.fn
      -- Like builtin.previewer.file/buffer, get the content as an array of
      -- lines through a host function (split()) rather than splitting the
      -- string in Lua; vim.split() is Neovim-only and lese runs on Vim too.
      return { content = fn.split(fn.getreg(params.item.detail.register.name), "\n") }
    end,
  })
end

-- {before}: true pastes before the cursor (like "{reg}P"), false after
-- (like "{reg}p"); matches ddu-source-register's insert/append actions.
local function register_paste_action(before)
  return define.action({
    name = before and "custom.action.register_insert" or "custom.action.register_append",
    invoke = function(ctx, params)
      local keystroke = before and "P" or "p"
      for _, item in ipairs(params.selected_items or { params.item }) do
        local name = item.detail.register.name
        -- '"' is itself the register-select prefix, so e.g. '""p' would
        -- select register '"' then try to use 'p' as a 2nd register name;
        -- plain 'p'/'P' already targets the unnamed register by default.
        local keys = name == '"' and keystroke or string.format('"%s%s', name, keystroke)
        local ok, err = pcall(ctx.host.cmd, "normal! " .. keys)
        if not ok then
          ctx.host.echo(
            string.format("[lese] Failed to paste register '%s': %s", name, tostring(err)),
            "WarningMsg"
          )
        end
      end
    end,
  })
end

---@param x lese.Entrypoint
return function(x)
  x.refine_setting({
    coordinator = builtin.coordinator.modern(),
    theme = builtin.theme.MODERN,
  })

  for _, picker in ipairs({
    { "grep", builtin.curator.grep() },
    { "git-grep", builtin.curator.git_grep() },
    { "rg", builtin.curator.rg() },
  }) do
    x.define_picker_from_curator(
      picker[1],
      std.refine_curator(picker[2], builtin.refiner.relative_path()),
      {
        sorters = sorters(),
        renderers = { builtin.renderer.nerdfont(), builtin.renderer.noop() },
        previewers = { builtin.previewer.file() },
        actions = merge(path_actions, quickfix_actions, misc_actions),
        default_action = "open",
      }
    )
  end

  x.define_picker_from_source(
    "file",
    std.refine_source(
      builtin.source.file({ filter_file = filter_file, filter_directory = filter_directory }),
      builtin.refiner.relative_path()
    ),
    {
      matchers = { builtin.matcher.fzf() },
      sorters = sorters(),
      renderers = {
        std.compose_renderers(builtin.renderer.smart_path(), builtin.renderer.nerdfont()),
        builtin.renderer.nerdfont(),
        builtin.renderer.noop(),
      },
      previewers = { builtin.previewer.file() },
      actions = merge(path_actions, quickfix_actions, misc_actions),
      default_action = "open",
    }
  )

  x.define_picker_from_source(
    "file:all",
    std.refine_source(builtin.source.file(), builtin.refiner.relative_path()),
    {
      matchers = { builtin.matcher.fzf() },
      sorters = sorters(),
      renderers = {
        std.compose_renderers(builtin.renderer.smart_path(), builtin.renderer.nerdfont()),
        builtin.renderer.nerdfont(),
        builtin.renderer.noop(),
      },
      previewers = { builtin.previewer.file() },
      actions = merge(path_actions, quickfix_actions, misc_actions),
      default_action = "open",
    }
  )

  x.define_picker_from_source("line", builtin.source.line(), {
    matchers = { builtin.matcher.fzf() },
    previewers = { builtin.previewer.buffer() },
    actions = merge(
      quickfix_actions,
      misc_actions,
      builtin.action.default_open_actions,
      builtin.action.default_buffer_actions
    ),
    default_action = "open",
    coordinator = builtin.coordinator.modern({ hide_preview = true }),
  })

  x.define_picker_from_source("buffer", builtin.source.buffer({ filter = "bufloaded" }), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    previewers = { builtin.previewer.buffer() },
    actions = merge(
      quickfix_actions,
      misc_actions,
      builtin.action.default_open_actions,
      builtin.action.default_buffer_actions
    ),
    default_action = "open",
  })

  x.define_picker_from_source("help", builtin.source.helptag(), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    previewers = { builtin.previewer.helptag() },
    actions = merge(misc_actions, builtin.action.default_help_actions),
    default_action = "help",
  })

  x.define_picker_from_source("quickfix", builtin.source.quickfix(), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    previewers = { builtin.previewer.buffer() },
    actions = merge(builtin.action.default_open_actions, misc_actions),
    default_action = "open",
  })

  x.define_picker_from_source(
    "oldfiles",
    std.refine_source(
      builtin.source.oldfiles(),
      builtin.refiner.cwd(),
      builtin.refiner.exists(),
      builtin.refiner.relative_path()
    ),
    {
      matchers = { builtin.matcher.fzf() },
      sorters = sorters(),
      previewers = { builtin.previewer.file() },
      actions = merge(path_actions, quickfix_actions, misc_actions),
      default_action = "open",
    }
  )

  x.define_picker_from_source("history", builtin.source.history(), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    actions = merge({ cmd = builtin.action.cmd({ immediate = true }) }, misc_actions),
    default_action = "cmd",
  })

  x.define_picker_from_source("register", register_source(), {
    matchers = { builtin.matcher.fzf() },
    previewers = { register_previewer() },
    actions = merge(misc_actions, {
      insert = register_paste_action(true),
      append = register_paste_action(false),
    }),
    default_action = "append",
  })
end
