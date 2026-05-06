-- lua_source {{{
vim.api.nvim_create_autocmd({ "TabEnter", "WinEnter", "CursorHold", "FocusGained" }, {
  group = "MyAutoCmd",
  pattern = "*",
  callback = function()
    pcall(vim.fn["ddu#ui#do_action"], "checkItems")
  end,
})
-- }}}

-- lua_ddu-filer {{{
local opts = { buffer = true, }
vim.keymap.set('n', "<CR>",
  function()
    vim.fn["ddu#ui#do_action"]("itemAction")
  end, opts)
vim.keymap.set('n', "<Space>",
  function()
    vim.fn["ddu#ui#do_action"]("toggleSelectItem")
  end, opts)
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
vim.keymap.set('n', 'o',
  function()
    vim.fn["ddu#ui#do_action"]("expandItem",
      { mode = "toggle", isGrouped = true, isInTree = false })
  end, opts)
vim.keymap.set('n', 'O',
  function()
    vim.fn["ddu#ui#do_action"]("expandItem",
      { maxLevel = -1 })
  end, opts)
vim.keymap.set('n', 'P',
  function()
    vim.fn["ddu#ui#do_action"]("togglePreview")
  end, opts)
vim.keymap.set('n', 'q',
  function()
    vim.fn["ddu#ui#do_action"]("quit")
  end, opts)
vim.keymap.set('n', 't',
  function()
    vim.fn["ddu#ui#do_action"]("itemAction", {
        name = "open",
        params = { command = "tabedit" },
    })
  end, opts)
vim.keymap.set('n', '<C-l>',
    function()
        vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
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
vim.keymap.set('n', "<C-d>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x04" }) -- \x04 is ASCII code of <C-d>
    end, opts)
vim.keymap.set('n', "<C-u>",
    function()
        vim.fn["ddu#ui#do_action"]("previewExecute", { command = "normal! \x15" }) -- \x15 is ASCII code of <C-u>
    end, opts)
-- }}}

-- lua_add {{{
local source_win_info = {}

local function filer_ui_params_h()
    if vim.tbl_isempty(source_win_info) then return {} end
    local pos    = source_win_info.pos
    local height = source_win_info.height
    local width  = source_win_info.width - 4

    local win_height  = math.min(math.floor(height / 4), 20)
    local win_col     = pos[2] + 1
    local win_row     = pos[1] + height - win_height - 3
    local preview_col = win_col + math.floor(width / 2)
    return {
        winRow        = win_row,
        winCol        = win_col,
        winWidth      = width,
        winHeight     = win_height,
        previewRow    = win_row + 1,
        previewCol    = preview_col,
        previewWidth  = width - math.floor(width / 2) - 2,
        previewHeight = win_height - 2,
    }
end

local function filer_ui_params_v()
    if vim.tbl_isempty(source_win_info) then return {} end
    local pos    = source_win_info.pos
    local height = source_win_info.height
    local width  = source_win_info.width

    local win_width   = math.min(math.floor(width / 4), 40)
    local win_height  = height - 3
    local win_col     = pos[2] + width - win_width - 2
    local win_row     = pos[1]
    local preview_row = win_row + math.floor(win_height / 2)
    return {
        winRow        = win_row,
        winCol        = win_col,
        winWidth      = win_width,
        winHeight     = win_height,
        previewRow    = preview_row,
        previewCol    = win_col + 1,
        previewWidth  = win_width - 2,
        previewHeight = win_height - math.floor(win_height / 2) - 2,
    }
end

local ddu_filer_opts = {
    ui      = "filer",
    name    = "filer" .. tostring(vim.fn.win_getid()),
    sources = { "file" },
    resume  = true,
    sync    = true,
    sourceOptions = {
        file = {
            path      = vim.b.ddu_ui_filter_path or vim.fn.getcwd(),
            limitPath = vim.fn.getcwd(),
            columns   = { "icon_filename" },
        },
    },
}

local function open_filer(ui_params, name_suffix)
    local win = vim.api.nvim_get_current_win()
    source_win_info = {
        pos    = vim.api.nvim_win_get_position(win),
        height = vim.api.nvim_win_get_height(win),
        width  = vim.api.nvim_win_get_width(win),
    }
    vim.fn["ddu#start"](vim.tbl_extend("force", ddu_filer_opts, {
        name     = ddu_filer_opts.name .. name_suffix,
        uiParams = { filer = ui_params() },
    }))
end

vim.keymap.set('n', "[Space]f", function() open_filer(filer_ui_params_h, "_h") end)
vim.keymap.set('n', "[Space]v", function() open_filer(filer_ui_params_v, "_v") end)
-- }}}
