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
vim.keymap.set('n', "<CR>",
    function()
        local item = vim.fn["ddu#ui#get_item"]()
        local action = item.action or {}
        local is_directory = action.isDirectory or false
        vim.fn["ddu#ui#do_action"]("itemAction",
            is_directory and { name = "narrow" } or { name = "default" })
    end, { buffer = true, desc = "ddu-ff: narrow into directory, otherwise run the default item action" })
vim.keymap.set('n', "<Space>",
    function()
        vim.fn["ddu#ui#do_action"]("toggleSelectItem")
    end, { buffer = true, silent = true, desc = "ddu-ff: toggle selection of the item" })
vim.keymap.set('n', 'a',
    function()
        vim.fn["ddu#ui#do_action"]("chooseAction")
    end, { buffer = true, desc = "ddu-ff: choose an item action from a list" })
vim.keymap.set('n', 'A',
    function()
        vim.fn["ddu#ui#do_action"]("inputAction")
    end, { buffer = true, desc = "ddu-ff: input an item action name" })
vim.keymap.set('n', 'gr',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", { name = "grep" })
  end, { buffer = true, desc = "ddu-ff: grep from the path of the item" })
vim.keymap.set('n', 'i',
    function()
        vim.fn["ddu#ui#do_action"]("openFilterWindow")
    end, { buffer = true, desc = "ddu-ff: open the filter input window" })
vim.keymap.set('n', 'K',
    function()
        vim.fn["ddu#ui#do_action"]("kensaku")
    end, { buffer = true, desc = "ddu-ff: switch to the kensaku (migemo) matcher" })
vim.keymap.set('n', 'n',
    function()
        vim.fn["ddu#ui#do_action"]("itemAction", { name = "narrow" })
    end, { buffer = true, desc = "ddu-ff: narrow the source into the item" })
vim.keymap.set('n', 'o',
    function()
        vim.fn["ddu#ui#do_action"]("expandItem", { mode = "toggle" })
    end, { buffer = true, desc = "ddu-ff: toggle expansion of the item (tree)" })
vim.keymap.set('n', 'P',
    function()
        vim.fn["ddu#ui#do_action"]("togglePreview", { mode = "toggle" })
    end, { buffer = true, desc = "ddu-ff: toggle the preview window" })
vim.keymap.set('n', 'q',
    function()
        vim.fn["ddu#ui#do_action"]("quit")
    end, { buffer = true, desc = "ddu-ff: quit ddu" })
vim.keymap.set('n', 's',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", {
      name = "open",
      params = { command = "split" }
    })
  end, { buffer = true, desc = "ddu-ff: open the item in a horizontal split" })
vim.keymap.set('n', 'v',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", {
      name = "open",
      params = { command = "vsplit" }
    })
  end, { buffer = true, desc = "ddu-ff: open the item in a vertical split" })
vim.keymap.set('n', '<C-l>',
    function()
        vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
    end, { buffer = true, desc = "ddu-ff: refresh the items of the sources" })
vim.keymap.set('n', "<C-d>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x04" }) -- \x04 is ASCII code of <C-d>
    end, { buffer = true, desc = "ddu-ff: scroll the preview window down" })
vim.keymap.set('n', "<C-u>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x15" }) -- \x15 is ASCII code of <C-u>
    end, { buffer = true, desc = "ddu-ff: scroll the preview window up" })
-- }}}
