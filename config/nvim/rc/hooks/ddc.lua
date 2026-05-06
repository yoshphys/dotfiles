-- lua_source {{{
local hook_source = vim.env.VIM_CONFIG_PATH .. "/rc/ts/ddc.ts"
vim.fn["ddc#custom#load_config"](hook_source)
vim.fn["ddc#enable"]({ context_filetype = "treesitter" })
-- }}}

-- lua_add {{{
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = "MyAutoCmd",
  callback = function()
      if vim.fn["pum#visible"]() then
          vim.fn["ddc#hide"]()
          vim.fn["pum#close"]()
      end
  end,
})

vim.keymap.set('c', "<C-n>", function()
    if vim.fn["pum#visible"]() then
        return vim.fn["pum#map#select_relative"](1)
    end
    vim.fn["ddc#map#manual_complete"]()
end)

vim.keymap.set('c', "<C-p>", function()
    if vim.fn["pum#visible"]() then
        return vim.fn["pum#map#select_relative"](-1)
    end
    vim.fn["ddc#map#manual_complete"]()
end)

vim.keymap.set({ 'i', 'c' }, "<C-y>", function()
    if vim.fn["pum#entered"]() then
        return vim.fn["pum#map#confirm"]()
    end
    return "<C-y>"
end, { expr = true })

vim.keymap.set({ 'i', 'c' }, "<C-g>", function()
  if vim.fn["pum#visible"]() then
      vim.fn["ddc#hide"]()
      vim.fn["pum#close"]()
      -- return vim.fn["pum#map#cancel"]()
      return ""
  end
  return "<C-g>"
end, { expr = true, nowait = true })

function CommandlinePre(mode)
    if vim.fn.exists("*ddc#enable_cmdline_completion") == 0 then
        return
    end
    if vim.fn.exists("*ddc#custom#get_buffer") == 1 then
        vim.b.prev_buffer_config = vim.fn["ddc#custom#get_buffer"]()
    end
    if mode == ':' then
        vim.fn["ddc#custom#patch_buffer"]("sourceOptions", {
            _ = {
                keywordPattern = "[0-9a-zA-Z_:#*/.-]*",
            },
        })
        vim.fn["ddc#custom#set_context_buffer"](function()
            if vim.fn.stridx(vim.fn.getcmdline(), '!') == 0 then
                return {
                    cmdlineSources = {
                        "shell-native",
                        "cmdline",
                        "cmdline_history",
                        "around",
                    },
                }
            else
                return {}
            end
        end)
    end
    vim.api.nvim_create_autocmd("User", {
        group = "MyAutoCmd",
        pattern = "DDCCmdlineLeave",
        once = true,
        callback = function()
            if vim.b.prev_buffer_config ~= nil then
                vim.fn["ddc#custom#set_buffer"](vim.b.prev_buffer_config)
                vim.b.prev_buffer_config = nil
            end
        end
    })
    vim.fn["ddc#enable_cmdline_completion"]()
end

vim.keymap.set({ 'n', 'x' }, ':', "<CMD>lua CommandlinePre(':')<CR>:")
vim.keymap.set('n', '?', "<CMD>lua CommandlinePre('/')<CR>?")
-- }}}
