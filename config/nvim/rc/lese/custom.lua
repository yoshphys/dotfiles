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
-- lese's own floating windows (the input/list/help components; see
-- lua/lese/host/nvim.lua's window_open()) are real, loaded buffers too --
-- unlisted, but builtin.source.buffer's "bufloaded" filter doesn't check
-- that -- so without this, every "buffer" picker session lists its own
-- input/list/help buffers among the candidates. bufhidden=wipe is how
-- lese marks them (and how other plugins mark similarly-ephemeral
-- scratch buffers, e.g. vim-fern's rename/action prompts), so exclude it
-- generally rather than naming lese's buffers specifically.
local function exclude_ephemeral_buffers()
  return define.refiner({
    name = "custom.refiner.exclude_ephemeral_buffers",
    refine = function(ctx, item)
      if ctx.host.fn.getbufvar(item.detail.bufnr, "&bufhidden") == "wipe" then
        return nil
      end
      return item
    end,
  })
end

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

-- custom.source.snippet: every hrsh7th/vim-vsnip snippet applicable to the
-- buffer that was current when ";s" was pressed (vsnip#source#find resolves
-- the filetype itself, including "global" and any g:vsnip_filetypes
-- aliasing; current buffer is captured here, not at preview/action time --
-- by then it is the picker's own UI buffer, not the one ";s" was pressed in).
local function snippet_source()
  return define.source({
    name = "custom.source.snippet",
    -- Like builtin.source.line, args[1] (rc/lazy.toml passes ";s"'s bufnr
    -- explicitly) picks the buffer, rather than this reading "%" itself.
    collect = function(ctx, params)
      local fn = ctx.host.fn
      local bufnr = fn.bufnr(tonumber(params.args[1]) or params.args[1] or "%")
      local filetype = fn.getbufvar(bufnr, "&filetype")
      local id = 0
      for _, source in ipairs(fn["vsnip#source#find"](bufnr)) do
        for _, snippet in ipairs(source) do
          id = id + 1
          local description = snippet.description ~= "" and snippet.description or snippet.label
          ctx:emit({
            id = id,
            value = string.format("%s - %s", table.concat(snippet.prefix, ", "), description),
            detail = { vsnip = { body = snippet.body, filetype = filetype } },
          })
        end
      end
    end,
  })
end

local function snippet_previewer()
  return define.previewer({
    name = "custom.previewer.snippet",
    preview = function(_, params)
      -- snippet.body is already an array of lines, unlike the register
      -- previewer's content: no split() needed.
      return { content = params.item.detail.vsnip.body, filetype = params.item.detail.vsnip.filetype }
    end,
  })
end

-- Expands at the cursor directly with vsnip#anonymous(), rather than typing
-- the prefix and relying on vsnip#expand()'s own prefix search: the picker
-- already chose the exact snippet, so there is no prefix left to match.
-- vsnip#anonymous() enters insert mode itself when called from Normal mode
-- (see vsnip's autoload/vsnip/session.vim's jump()), so no mode handling
-- is needed here.
local function snippet_expand_action()
  return define.action({
    name = "custom.action.snippet_expand",
    invoke = function(ctx, params)
      local fn = ctx.host.fn
      for _, item in ipairs(params.selected_items or { params.item }) do
        fn["vsnip#anonymous"](table.concat(item.detail.vsnip.body, "\n"))
      end
    end,
  })
end

-- Which maplist() .mode values count as "the current mode", for the
-- {mode_char} <F1> was pressed in (see rc/lazy.toml's nnoremap/inoremap/
-- xnoremap <F1> ..., one literal mode_char per map command -- not read
-- from mode() here, since by the time :Lese runs, the mode may already
-- have changed). ' ' is plain :map's "Normal+Visual+Select+Operator-
-- pending", '!' is :map!'s "Insert+Cmdline"; both are mode-combining
-- wildcards a single-mode filter must also match.
local function keymap_mode_filters(mode_char)
  if mode_char == "i" then
    return { i = true, ["!"] = true }
  elseif mode_char == "x" then
    return { v = true, x = true, [" "] = true }
  else
    return { n = true, [" "] = true }
  end
end

-- custom.source.keymap: every global or buffer-local mapping (maplist(),
-- the same portable-across-Vim-and-Neovim function lese's own
-- autoload/lese/internal/mapping.vim uses) active in args[1]'s mode.
-- detail.launch_mode (the same args[1]) is what keymap_execute_action()
-- re-enters before feeding the mapping's keys, since not every mapping is
-- bound to a key the user would otherwise know to press.
local function keymap_source()
  return define.source({
    name = "custom.source.keymap",
    collect = function(ctx, params)
      local fn = ctx.host.fn
      local launch_mode = params.args[1] or "n"
      local filters = keymap_mode_filters(launch_mode)
      local id = 0
      for _, m in ipairs(fn.maplist()) do
        if filters[m.mode] then
          id = id + 1
          local rhs = m.rhs ~= "" and m.rhs or "<callback>"
          ctx:emit({
            id = id,
            value = string.format("%s%-15s %s", m.buffer == 1 and "[buf] " or "", m.lhs, rhs),
            detail = { keymap = m, launch_mode = launch_mode },
          })
        end
      end
    end,
  })
end

local function keymap_previewer()
  return define.previewer({
    name = "custom.previewer.keymap",
    preview = function(ctx, params)
      local fn = ctx.host.fn
      local m = params.item.detail.keymap
      local function flag(name, value)
        return string.format("%-8s %s", name .. ":", value == 1 and "yes" or "no")
      end
      local lines = {
        "lhs:     " .. m.lhs,
        "mode:    " .. m.mode,
        flag("buffer", m.buffer),
        flag("noremap", m.noremap),
        flag("silent", m.silent),
        flag("expr", m.expr),
        flag("nowait", m.nowait),
        "",
        "rhs:",
      }
      if m.rhs ~= "" then
        for _, line in ipairs(fn.split(m.rhs, "\n")) do
          lines[#lines + 1] = line
        end
      else
        lines[#lines + 1] = "<Lua callback, no text rhs>"
        if m.desc and m.desc ~= "" then
          lines[#lines + 1] = "desc: " .. m.desc
        end
      end
      -- sid <= 0 means "not defined from a script" (the command line, or a
      -- Lua callback registered without one); getscriptinfo() only exists
      -- on recent Vim/Neovim, hence the pcall.
      if m.sid and m.sid > 0 then
        local ok, info = pcall(fn.getscriptinfo, { sid = m.sid })
        if ok and info and info[1] then
          lines[#lines + 1] = ""
          lines[#lines + 1] = string.format("Last set from %s:%d", info[1].name, m.lnum or 0)
        end
      end
      return { content = lines }
    end,
  })
end

-- Feeds the mapping's raw key sequence back through Vim's own mapping
-- engine (feedkeys(), remapped and executed immediately) rather than
-- interpreting rhs/callback ourselves, so <expr> mappings and Lua-callback
-- mappings resolve exactly as if the user had pressed lhs. Insert/Visual
-- mappings need their mode re-entered first (lhsraw alone, typed from
-- Normal mode, would not resolve against an i/x-mode mapping at all); "gv"
-- reselects whatever Visual area was active when the picker was opened.
local function keymap_execute_action()
  return define.action({
    name = "custom.action.keymap_execute",
    invoke = function(ctx, params)
      local fn = ctx.host.fn
      for _, item in ipairs(params.selected_items or { params.item }) do
        local m = item.detail.keymap
        local keys = m.lhsraw
        if item.detail.launch_mode == "i" then
          keys = "i" .. keys
        elseif item.detail.launch_mode == "x" then
          keys = "gv" .. keys
        end
        fn.feedkeys(keys, "mtx")
      end
    end,
  })
end

-- custom.source.tab: every tab page but the current one, labeled with the
-- set of buffers its windows show (deduplicated, same buffer in two
-- splits of the one tab counts once). detail.bufnr is the *active*
-- window's buffer specifically, not nested, since that is what
-- builtin.previewer.buffer() itself expects for the preview.
local function tab_source()
  return define.source({
    name = "custom.source.tab",
    collect = function(ctx)
      local fn = ctx.host.fn
      local current = fn.tabpagenr()
      local id = 0
      for _, t in ipairs(fn.gettabinfo()) do
        if t.tabnr ~= current then
          id = id + 1
          local buflist = fn.tabpagebuflist(t.tabnr)
          local activeBufnr = buflist[fn.tabpagewinnr(t.tabnr)]
          local seen, names = {}, {}
          for _, bufnr in ipairs(buflist) do
            if not seen[bufnr] then
              seen[bufnr] = true
              local bufname = fn.bufname(bufnr)
              names[#names + 1] = bufname == "" and "[No Name]" or fn.fnamemodify(bufname, ":t")
            end
          end
          ctx:emit({
            id = id,
            value = string.format("%d  %s", t.tabnr, table.concat(names, ", ")),
            detail = { bufnr = activeBufnr, tab = { tabnr = t.tabnr } },
          })
        end
      end
    end,
  })
end

-- Switching to several tabs at once makes no sense, so this ignores
-- selected_items and always acts on the item under the cursor.
local function tab_switch_action()
  return define.action({
    name = "custom.action.tab_switch",
    invoke = function(ctx, params)
      ctx.host.cmd("tabnext " .. params.item.detail.tab.tabnr)
    end,
  })
end

-- The same shell history files goda-cmp's shellhistory source reads (see
-- rc/goda-cmp/main.go's shellHistories); kept in sync by hand, since a Go
-- module and this Lua file can't share one literal.
local shell_history_paths = { "~/.cache/ddt-shell-history", "~/.zsh_history" }

-- Parses a shell history file the same way goda-cmp-ext's shellhistory
-- source does: zsh's extended-history format (": <epoch>:<duration>;cmd")
-- is unwrapped, and a trailing backslash continues the command onto the
-- next line (zsh's own line continuation, also how goda-term-ui-shell
-- writes a multi-line command). Returns commands newest first; a
-- multi-line one is dropped, since it can't go on setCommandLine's one
-- line either.
local function read_shell_history(path)
  local f = io.open(path, "r")
  if f == nil then
    return {}
  end
  local content = f:read("a")
  f:close()

  local cmds, cont = {}, nil
  for line in (content .. "\n"):gmatch("(.-)\n") do
    if line:sub(-1) == "\\" then
      cont = (cont or "") .. line:sub(1, -2) .. "\n"
    else
      if cont then
        line = cont .. line
        cont = nil
      end
      line = line:match("^: %d+:%d+;(.*)$") or line
      if line ~= "" and not line:find("\n") then
        cmds[#cmds + 1] = line
      end
    end
  end

  local seen, uniq = {}, {}
  for i = #cmds, 1, -1 do
    if not seen[cmds[i]] then
      seen[cmds[i]] = true
      uniq[#uniq + 1] = cmds[i]
    end
  end
  return uniq
end

-- custom.source.shellhistory: the commands of shell_history_paths above.
-- rc/goda-term.vim's goda-term-shell ftplugin block maps <C-r> to this
-- picker (buffer-local, insert and normal mode): the eventual
-- replacement of ddt.vim's old <C-h> shell-history search (goda-fi.vim,
-- ddu.vim's own successor, is still not adopted).
local function shellhistory_source()
  return define.source({
    name = "custom.source.shellhistory",
    collect = function(ctx)
      local fn = ctx.host.fn
      local seen, id = {}, 0
      for _, path in ipairs(shell_history_paths) do
        for _, cmd in ipairs(read_shell_history(fn.expand(path))) do
          if not seen[cmd] then
            seen[cmd] = true
            id = id + 1
            ctx:emit({ id = id, value = cmd, detail = { command = cmd } })
          end
        end
      end
    end,
  })
end

-- Starts a fresh goda-term-shell prompt with the chosen command, ready to
-- edit or run -- unlike goda-term-ui-shell's own "send" action, which
-- would run it immediately.
-- The list column truncates a long command; show it in full, with shell
-- syntax highlighting, in the preview instead.
local function shellhistory_previewer()
  return define.previewer({
    name = "custom.previewer.shellhistory",
    preview = function(_, params)
      return { content = { params.item.detail.command }, filetype = "sh" }
    end,
  })
end

local function shellhistory_setcommandline_action()
  return define.action({
    name = "custom.action.shellhistory_setcommandline",
    invoke = function(ctx, params)
      ctx.host.fn["goda_term#ui#do_action"]("setCommandLine", { str = params.item.detail.command })
    end,
  })
end

local diagnostic_severity_labels = { "E", "W", "I", "H" } -- vim.diagnostic.severity.{ERROR,WARN,INFO,HINT}

-- custom.source.diagnostic: every LSP diagnostic across every buffer, via
-- Neovim's own vim.diagnostic.get() -- a no-op on plain Vim, which has no
-- portable equivalent, the same reason goda-cmp's LSP completion source
-- is called "nvimlsp" rather than just "lsp".
local function diagnostic_source()
  return define.source({
    name = "custom.source.diagnostic",
    collect = function(ctx)
      if vim.diagnostic == nil then
        return
      end
      local fn = ctx.host.fn
      local diags = vim.diagnostic.get(nil)
      table.sort(diags, function(a, b)
        if a.bufnr ~= b.bufnr then
          return a.bufnr < b.bufnr
        end
        if a.lnum ~= b.lnum then
          return a.lnum < b.lnum
        end
        return a.col < b.col
      end)
      local id = 0
      for _, d in ipairs(diags) do
        id = id + 1
        local bufname = fn.bufname(d.bufnr)
        bufname = bufname == "" and "[No Name]" or fn.fnamemodify(bufname, ":~:.")
        local label = diagnostic_severity_labels[d.severity] or "?"
        local message = d.message:gsub("\n", " ")
        ctx:emit({
          id = id,
          value = string.format("[%s] %s:%d  %s", label, bufname, d.lnum + 1, message),
          detail = { bufnr = d.bufnr, line = d.lnum + 1, column = d.col + 1 },
        })
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

  x.define_picker_from_source(
    "buffer",
    std.refine_source(builtin.source.buffer({ filter = "bufloaded" }), exclude_ephemeral_buffers()),
    {
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
    }
  )

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

  x.define_picker_from_source("snippet", snippet_source(), {
    matchers = { builtin.matcher.fzf() },
    previewers = { snippet_previewer() },
    actions = merge(misc_actions, { expand = snippet_expand_action() }),
    default_action = "expand",
  })

  x.define_picker_from_source("keymap", keymap_source(), {
    matchers = { builtin.matcher.fzf() },
    previewers = { keymap_previewer() },
    actions = merge(misc_actions, { execute = keymap_execute_action() }),
    default_action = "execute",
  })

  x.define_picker_from_source("tab", tab_source(), {
    matchers = { builtin.matcher.fzf() },
    previewers = { builtin.previewer.buffer() },
    actions = merge(misc_actions, { switch = tab_switch_action() }),
    default_action = "switch",
  })

  x.define_picker_from_source("diagnostic", diagnostic_source(), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    previewers = { builtin.previewer.buffer() },
    actions = merge(builtin.action.default_open_actions, misc_actions),
    default_action = "open",
  })

  x.define_picker_from_source("shellhistory", shellhistory_source(), {
    matchers = { builtin.matcher.fzf() },
    sorters = sorters(),
    previewers = { shellhistory_previewer() },
    actions = merge(misc_actions, { setCommandLine = shellhistory_setcommandline_action() }),
    default_action = "setCommandLine",
  })
end
