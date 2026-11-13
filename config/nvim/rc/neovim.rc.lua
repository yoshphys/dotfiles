-- Neovim-only settings: either a Neovim-only option/API (winblend, pumblend,
-- vim.diagnostic, setcmdline()), or tied to Neovim-only infrastructure
-- (packadd of a Neovim runtime package, the Rex scrollback buffers).

-- mapping ---------------------------------------
vim.keymap.set('n', "[Space]m", function()
  vim.o.mouse = vim.o.mouse == "" and "nvi" or ""
  vim.notify("mouse=" .. vim.o.mouse)
end, { desc = "Toggle the mouse option" })

vim.keymap.set('c', "<C-k>", function()
  local cmd = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()
  vim.fn.setcmdline(string.sub(cmd, 1, pos - 1))
  vim.fn.setcmdpos(pos)
  return ''
end, { expr = true, desc = "Cmdline: delete from the cursor to the end of the line" })

-- appearances -------------------------------------
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.diagnostic.config { severity_sort = true }

-- builtin plugins ---------------------------------
vim.cmd.packadd('nvim.undotree')

-- auto command ------------------------------------
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

-- Buffers that Rex's cmd+y opens: a frozen snapshot of a pane's scrollback,
-- there only to read and pick text out of. Searching and moving are vim's own;
-- these two only shorten copying to the system clipboard.
vim.api.nvim_create_autocmd('BufEnter', {
  group = "MyAutoCmd",
  pattern = '*/rex-scrollback-*.log',
  callback = function(args)
    vim.keymap.set('x', 'y', '"+y', {
      buffer = args.buf,
      desc = 'Rex scrollback: yank to the clipboard',
    })
    vim.keymap.set('x', 'Y', '"+y<Cmd>qa!<CR>', {
      buffer = args.buf,
      desc = 'Rex scrollback: yank to the clipboard and close the pane',
    })
  end,
  desc = 'Map y and Y in a Rex scrollback snapshot buffer',
})
