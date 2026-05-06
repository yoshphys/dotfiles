-- lua_add {{{
vim.api.nvim_create_autocmd("User", {
  pattern = "LspointsAttach:*",
  callback = function()
    vim.keymap.set('n', "gf", function()
      vim.fn["denops#request"]("lspoints", "executeCommand", {
        "format",
        "execute",
        vim.api.nvim_get_current_buf(),
      })
    end, {buffer = true})
  end,
})
-- }}}

-- lua_source {{{
vim.fn["lspoints#load_extensions"]({
  -- "config",
  "format",
  "nvim_diagnostics",
})
-- vim.fn["lspoints#settings#patch"]({
--   tracePath = "/tmp/lspoints",
-- })

local function filetype_callback(filetype, func)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetype,
    callback = func
  })
end

-- local function find_config_path(filenames)
--   local rootdir = nil
--   local cwd = nil
--   local filepath = vim.api.nvim_buf_get_name(0)
--   if filepath ~= "" then
--     cwd = vim.fn.fnamemodify(filepath, ":h")
--   else
--     cwd = vim.fn.getcwd()
--   end
--   local path = vim.fs.find(filenames, {
--     path = cwd,
--     upward = true,
--     limit = math.huge,
--   })
--   vim.notify(vim.inspect(path))
--   for _, ipath in ipairs(path) do
--     if ipath ~= "" then
--       rootdir = ipath
--     end
--   end
--   return rootdir
-- end

-- c/cpp -----------------------------------------
filetype_callback("cpp", function()
  vim.fn["lspoints#attach"]("clangd", {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--offset-encoding=utf-16",
      "--function-arg-placeholders=false",
      "--header-insertion=never",
      -- "--log=verbose",
    },
  })
end)


-- julia -----------------------------------------
filetype_callback("julia", function()
  vim.fn["lspoints#attach"]("julia", {
    cmd = { vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia"),
      "--startup-file=no",
      "--history-file=no",
      "-e",
      [[
        # Load LanguageServer.jl: attempt to load from ~/.julia/environments/nvim-lspconfig
        # with the regular load path as a fallback
        ls_install_path = joinpath(
            get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
            "environments", "nvim-lspconfig"
        )
        pushfirst!(LOAD_PATH, ls_install_path)
        using LanguageServer
        popfirst!(LOAD_PATH)
        depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
        project_path = let
            dirname(something(
                ## 1. Finds an explicitly set project (JULIA_PROJECT)
                Base.load_path_expand((
                    p = get(ENV, "JULIA_PROJECT", nothing);
                    p === nothing ? nothing : isempty(p) ? nothing : p
                )),
                ## 2. Look for a Project.toml file in the current working directory,
                ##    or parent directories, with $HOME as an upper boundary
                Base.current_project(),
                ## 3. First entry in the load path
                get(Base.load_path(), 1, nothing),
                ## 4. Fallback to default global environment,
                ##    this is more or less unreachable
                Base.load_path_expand("@v#.#"),
            ))
        end
        @info "Running language server" VERSION pwd() project_path depot_path
        server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
        server.runlinter = true
        run(server)
      ]]
    },
    -- options = {
    --   rootPath = find_config_path({ "Project.toml", "JuliaProject.toml", ".git" }) or vim.fn.getcwd(),
    -- },
  })
end)

-- typst -----------------------------------------
filetype_callback("typst", function()
  vim.fn["lspoints#attach"]("tinymist", {
    cmd = { "tinymist" },
    initializationOptions = {
      formatterMode = "typstyle",
    }
  })
end)

-- }}}
