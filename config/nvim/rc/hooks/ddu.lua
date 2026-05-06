-- lua_source {{{
local hook_source = vim.env.VIM_CONFIG_PATH .. "/rc/ts/ddu.ts"
vim.fn["ddu#custom#load_config"](hook_source)
-- }}}

-- lua_add {{{

-- Disable autoAction while the cmdline filter window is open to prevent
-- E590 ("A preview window already exists") from concurrent preview calls.
-- Track state explicitly to avoid double-toggle when quit without filter.
-- local _filter_disabled_auto_action = false

vim.api.nvim_create_autocmd("User", {
    group = "MyAutoCmd",
    pattern = "Ddu:uiOpenFilterWindow",
    callback = function()
        _filter_disabled_auto_action = true
        vim.fn["ddu#ui#async_action"]("toggleAutoAction")
    end,
})
vim.api.nvim_create_autocmd("User", {
    group = "MyAutoCmd",
    pattern = "Ddu:uiCloseFilterWindow",
    callback = function()
        if _filter_disabled_auto_action then
            _filter_disabled_auto_action = false
            vim.fn["ddu#ui#async_action"]("toggleAutoAction")
        end
    end,
})
vim.api.nvim_create_autocmd("User", {
    group = "MyAutoCmd",
    pattern = "Ddu:uiQuit",
    callback = function()
        if _filter_disabled_auto_action then
            _filter_disabled_auto_action = false
            vim.fn["ddu#ui#async_action"]("toggleAutoAction")
        end
    end,
})

vim.keymap.set('n', "/", function()
    vim.fn["ddu#start"]({
      name = "search",
      resume = false,
      ui = {
        name = "ff",
      },
      sources = {
        {
          name = "line",
          params = { ignoreEmptyInput = true },
          options = { volatile = true }
        },
      },
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "Ddu:uiDone",
        once = true,
        nested = true,
        callback = function()
            vim.fn["ddu#ui#async_action"]("openFilterWindow")
        end,
    })
    end)

vim.keymap.set('n', "*", function()
    vim.fn["ddu#start"]({
      name = "search",
      resume = false,
      ui = {
        name = "ff",
        params = { ignoreEmpty = true },
      },
      sources = { "line" },
      input = vim.fn.expand('<cword>')
    })
    end)

vim.keymap.set('n', "n", function()
    vim.fn["ddu#start"]({
      name = "search",
      resume = true,
    })
    end)

vim.keymap.set('n', ";g", function()
    vim.fn["ddu#start"]({
      name = "ripgrep",
      resume = false,
      ui = {
        name = "ff",
      },
      sources = {
        {
          name = "rg",
          options = { volatile = true },
        },
      },
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "Ddu:uiDone",
        once = true,
        nested = true,
        callback = function()
            vim.fn["ddu#ui#async_action"]("openFilterWindow")
        end,
    })
    end)

vim.keymap.set('x', ";g", function()
    local selected = vim.fn.getregion(
      vim.fn.getpos('v'),
      vim.fn.getpos('.'),
      { type = vim.fn.mode() }
    )
    local text = table.concat(selected, "\n")
    vim.fn["ddu#start"]({
      name = "ripgrep",
      resume = false,
      ui = {
        name = "ff",
        params = { ignoreEmpty = true }
      },
      sources = {
        {
          name = "rg",
          options = { volatile = true }
        },
      },
      input = vim.fn.escape(text, " "),
    })
    end)

vim.keymap.set('n', ";G", function()
    vim.fn["ddu#start"]({
      name = "ripgrep",
      resume = false,
      ui = {
        name = "ff",
        params = { ignoreEmpty = true },
      },
      sources = {
        {
          name = "rg",
          options = { volatile = true },
        },
      },
      input = vim.fn.expand('<cword>')
    })
    end)

vim.keymap.set('n', ";r", function()
    vim.fn["ddu#start"]({
      name = "register",
      ui = {
        name = "ff",
        params = { autoResize = true },
      },
      sources = {
        {
          name = "register",
          options = { defaultAction = vim.fn.col('.') == 1 and 'insert' or 'append' },
        },
      },
    })
    end)

vim.keymap.set('n', ";b", function()
    vim.fn["ddu#start"]({
      name = "buffer",
      ui = "ff" ,
      sources = { "buffer" },
    })
    end)

vim.keymap.set('n', ";h", function()
    vim.fn["ddu#start"]({
      name = "command_history",
      ui = "ff",
      sources = { "command_history" },
    })
    end)

vim.keymap.set('n', ";H", function()
    vim.fn["ddu#start"]({
      name = "help",
      ui = "ff",
      sources = {
        {
          name = "help",
          options = { volatile = true },
        },
      },
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "Ddu:uiDone",
        once = true,
        nested = true,
        callback = function()
            vim.fn["ddu#ui#async_action"]("openFilterWindow")
        end,
    })
    end)

vim.keymap.set('n', "[Space]gs", function()
    vim.fn["ddu#start"]({
      name = "git_status",
      ui = {
        name = "ff",
        resume = true,
      },
      sources = { "git_status" },
    })
    end)

vim.keymap.set('n', "[Space]gl", function()
    vim.fn["ddu#start"]({
      name = "git_log",
      ui = {
        name = "ff",
        resume = true,
      },
      sources = { "git_log" },
    })
    end)

vim.keymap.set('n', "[Space]gS", function()
    vim.fn["ddu#start"]({
      name = "git_stash",
      ui = {
        name = "ff",
        resume = true,
      },
      sources = { "git_stash" },
    })
    end)

-- }}}
