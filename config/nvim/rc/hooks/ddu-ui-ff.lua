-- lua_source {{{
local function set_size()
    local cols       = vim.o.columns
    local lines      = vim.o.lines

    local win_col    = math.floor(cols / 8)
    local win_width  = cols - math.floor(cols / 4)
    local win_row    = math.floor(lines / 8)
    local win_height = lines - math.floor(lines / 4)

    vim.fn["cmdline#set_option"]({
        border = "rounded",
        col = win_col,
        row = win_row,
        width = math.floor(win_width / 2) - 1,
    })
    vim.fn["ddu#custom#patch_global"]({
        uiParams = {
            ff = {
                winCol        = win_col,
                winRow        = win_row + 3,
                winWidth      = math.floor(win_width / 2) - 1,
                winHeight     = win_height - 3,
                previewCol    = win_col + math.floor(win_width / 2) + 1,
                previewRow    = win_row + 3,
                previewWidth  = math.floor(win_width / 2) - 1,
                previewHeight = win_height - 3,
            }
        },
    })
end

set_size()

vim.api.nvim_create_autocmd("VimResized", {
    group = "MyAutoCmd",
    callback = set_size,
})
-- }}}

-- lua_ddu-ff {{{
local opts = { buffer = true, }
vim.keymap.set('n', "<CR>",
    function()
        local item = vim.fn["ddu#ui#get_item"]()
        local action = item.action or {}
        local is_directory = action.isDirectory or false
        vim.fn["ddu#ui#do_action"]("itemAction",
            is_directory and { name = "narrow" } or { name = "default" })
    end, opts)
vim.keymap.set('n', "<Space>",
    function()
        vim.fn["ddu#ui#do_action"]("toggleSelectItem")
    end, vim.tbl_extend('force', opts, { silent = true }))
vim.keymap.set('n', 'a',
    function()
        vim.fn["ddu#ui#do_action"]("chooseAction")
    end, opts)
vim.keymap.set('n', 'A',
    function()
        vim.fn["ddu#ui#do_action"]("inputAction")
    end, opts)
vim.keymap.set('n', 'gr',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", { name = "grep" })
  end, opts)
vim.keymap.set('n', 'i',
    function()
        vim.fn["ddu#ui#do_action"]("openFilterWindow")
    end, opts)
vim.keymap.set('n', 'K',
    function()
        vim.fn["ddu#ui#do_action"]("kensaku")
    end, opts)
vim.keymap.set('n', 'n',
    function()
        vim.fn["ddu#ui#do_action"]("itemAction", { name = "narrow" })
    end, opts)
vim.keymap.set('n', 'o',
    function()
        vim.fn["ddu#ui#do_action"]("expandItem", { mode = "toggle" })
    end, opts)
vim.keymap.set('n', 'P',
    function()
        vim.fn["ddu#ui#do_action"]("togglePreview", { mode = "toggle" })
    end, opts)
vim.keymap.set('n', 'q',
    function()
        vim.fn["ddu#ui#do_action"]("quit")
    end, opts)
vim.keymap.set('n', 's',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", {
      name = "open",
      params = { command = "split" }
    })
  end, opts)
vim.keymap.set('n', 'v',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", {
      name = "open",
      params = { command = "vsplit" }
    })
  end, opts)
vim.keymap.set('n', '<C-l>',
    function()
        vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
    end, opts)
vim.keymap.set('n', "<C-d>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x04" }) -- \x04 is ASCII code of <C-d>
    end, opts)
vim.keymap.set('n', "<C-u>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x15" }) -- \x15 is ASCII code of <C-u>
    end, opts)
-- }}}
