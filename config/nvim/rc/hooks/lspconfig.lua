-- lua_source {{{
-- NOTE: Disable lsp watcher. Too slow on linux
-- https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086

local function clear_lsp_log()
  local logfile = vim.lsp.log.get_filename()
  if not logfile or vim.fn.filereadable(logfile) == 0 then
    vim.notify("Cannot find LSP log", vim.log.levels.ERROR)
    return
  end
  os.remove(logfile)
  vim.notify("Successfully removed LSP log file: " .. logfile, vim.log.levels.INFO)
end
vim.api.nvim_create_user_command("LspClearLog", clear_lsp_log, {})

require("vim.lsp._watchfiles")._watchfunc = function()
  return function() end
end

--- function just after LspAttach ----------------
local function on_attach(on_attach_func)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      on_attach_func(client, bufnr)
    end,
  })
end

--- format keymap --------------------------------
on_attach(function(client, bufnr)
  vim.keymap.set('n', 'gf', '<Cmd>lua vim.lsp.buf.format()<CR>', { silent = true, buffer = bufnr })
  vim.keymap.set('n', 'K', "<Cmd>lua vim.lsp.buf.hover({border = 'single'})<CR>", { silent = true, buffer = bufnr })
  vim.keymap.set('n', '<C-w>d', "<Cmd>lua vim.diagnostic.open_float({border = 'single'})<CR>",
    { silent = true, buffer = bufnr })

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, bufnr) then
    vim.lsp.inline_completion.enable(true, { bufnr = bufnr })

    vim.keymap.set(
      'i',
      '<C-f>',
      vim.lsp.inline_completion.get,
      { desc = 'LSP: accept inline completion', buffer = bufnr }
    )
    vim.keymap.set(
      'i',
      '<C-e>',
      vim.lsp.inline_completion.select,
      { desc = 'LSP: switch inline completion', buffer = bufnr }
    )
  end
end)

-- on_attach(function(client, buffer)
--     require("illuminate").attach(client, buffer)
-- end)

--------------------------------------------------
-- indivisual settings for each servers ----------
--------------------------------------------------

local lsp_servers = {
  -- "copilot",
  "denols",       -- for deno
  "tinymist",     -- for typst
  "clangd",       -- for c/c++
  "lua_ls",       -- for lua
  -- "julials",      -- for julia
  "jetls",        -- for julia
  "basedpyright", -- for python
}

local capabilities = require("ddc_source_lsp").make_client_capabilities()
-- To disable snippets of LSP. Because I prefer to use snippets from plugin
capabilities.textDocument.completion.completionItem.snippetSupport = false
vim.lsp.config('*', {
  capabilities = capabilities
})

-- lua_ls ----------------------------------------
vim.lsp.config("lua_ls", {
  -- capabilities = capabilities,
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        }
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
        -- library = vim.api.nvim_get_runtime_file("", true)
      }
    })
  end,
  settings = {
    Lua = {}
  }
})

-- clangd ----------------------------------------
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--offset-encoding=utf-16",
    "--function-arg-placeholders=false",
    "--header-insertion=never",
    -- "--log=verbose",
  }
})

-- julials ---------------------------------------
-- vim.lsp.config("julials", {
--   on_new_config = function(new_config, _)
--     local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
--     if require("lspconfig").util.path.is_file(julia) then
--       new_config.cmd[1] = julia
--       new_config.capabilities = capabilities
--     end
--   end
-- })
-- vim.lsp.config('julials', {
--   filetypes = { "julia", 'aibo-prompt.aibo-tool-julia' },
-- })
vim.lsp.config("jetls", {
    cmd = {
        "jetls",
        "serve",
    },
    filetypes = { "julia" },
    root_markers = { "Project.toml" }
})

--------------------------------------------------
-- enabling servers ------------------------------
--------------------------------------------------

for _, server in pairs(lsp_servers) do
  vim.lsp.enable(server)
end

--------------------------------------------------
-- zk-lsp ----------------------------------------
--------------------------------------------------

vim.lsp.config('zk-lsp', {
  cmd = { "zk-lsp", "lsp" },
  filetypes = { "typst" },
  root_dir = function(bufnr)
    local wiki_root = vim.fn.expand("~/wiki")
    local buf_path = vim.api.nvim_buf_get_name(bufnr)
    if buf_path:find(wiki_root .. "/", 1, true) then
      return wiki_root
    end
    return vim.fs.root(bufnr, { "zk-lsp.toml" })
  end,
  offset_encoding = "utf-16",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function(ev)
    local cfg = vim.lsp.config['zk-lsp']
    local root = cfg.root_dir(ev.buf)
    if root then
      vim.lsp.start(vim.tbl_extend('force', cfg, { root_dir = root }), { bufnr = ev.buf })
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  pattern = "*.typ",
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "zk-lsp" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.typ",
  callback = function(ev)
    local buf_path = vim.api.nvim_buf_get_name(ev.buf)

    local wiki_root = vim.lsp.config['zk-lsp'].root_dir(ev.buf)
    if not wiki_root or not buf_path:find(wiki_root .. "/", 1, true) then
      return
    end

    local lines = vim.fn.readfile(buf_path, "b")
    local formatted = vim.fn.systemlist({ "zk-lsp", "--wiki-root", wiki_root, "format" }, lines)
    if vim.v.shell_error == 0 then
      vim.fn.writefile(formatted, buf_path, "b")
      vim.cmd("edit!")
    end
  end,
})

-- }}}
