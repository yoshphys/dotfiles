vim.api.nvim_create_augroup("MyAutoCmd", {})

-- mapping ---------------------------------------
-- [Space]: Other useful commands
-- Smart space mapping.
vim.api.nvim_set_keymap('n', "<Space>", "[Space]", { noremap = false })
-- vim.keymap.set('n', "<Space>", "[Space]", { noremap = false })
vim.keymap.set('n', "[Space]", "<Nop>")

vim.keymap.set('c', "<C-f>", "<Right>")
vim.keymap.set('c', "<C-b>", "<Left>")
vim.keymap.set('c', "<C-a>", "<Home>")
vim.keymap.set('c', "<C-e>", "<End>")
vim.keymap.set('c', "<C-d>", "<Delete>")
vim.keymap.set('c', "<C-k>", function()
  local cmd = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()
  vim.fn.setcmdline(string.sub(cmd, 1, pos - 1))
  vim.fn.setcmdpos(pos)
  return ''
end, {expr = true})

-- lang ------------------------------------------
vim.cmd "language en_US.UTF-8"
-- vim.opt.encoding = "utf-8"
-- vim.opt.fileencoding = "utf-8"
vim.opt.ambiwidth = "single"

-- clipboard -------------------------------------
vim.opt.clipboard:append { "unnamedplus" }

-- file ------------------------------------------
vim.opt.swapfile = false
vim.opt.hidden = true
vim.opt.backup = true
vim.opt.backupdir = os.getenv "HOME" .. "/.vim/backups"

-- indent ----------------------------------------
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- cursor ----------------------------------------
vim.opt.cursorline = true
vim.opt.guicursor = {
  "n-v-c:block-Cursor/lCursor-blinkon0",
  "i-ci:ver25-Cursor/lCursor",
  "r-cr:hor25-Cursor/lCursor",
  "t:ver25-Cursor/lCursor",
}
-- vim.opt.cursorcolumn = true

-- lining ----------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 8

-- menu and command ------------------------------
vim.opt.wildmenu = true
vim.opt.cmdheight = 1
vim.opt.showmode = false
vim.opt.laststatus = 2
vim.opt.showcmd = true

-- search/replace --------------------------------
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.matchtime = 1

-- appearances -----------------------------------
vim.opt.termguicolors = true
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.showtabline = 0 -- disabling tab line on the top
vim.opt.signcolumn = "yes:1"
vim.diagnostic.config { severity_sort = true }

-- dpp.vim ---------------------------------------
vim.cmd("source $VIM_CONFIG_PATH/rc/dpp.lua")

-- builtin plugins -------------------------------
vim.cmd.packadd('nvim.undotree')

-- misc ------------------------------------------
vim.g.tex_flavor = "latex"

-- auto command ----------------------------------
vim.api.nvim_create_autocmd('QuitPre', {
  group = "MyAutoCmd",
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= current_win then
        local buf = vim.api.nvim_win_get_buf(win)
        -- if the buffer is normal buffer, exit from the loop
        if vim.bo[buf].buftype == '' then
          return
        end
      end
    end
    -- close all the buffers other than current buffer
    vim.cmd.only({ bang = true })
  end,
  desc = 'Close all special buffers and quit Neovim',
})
