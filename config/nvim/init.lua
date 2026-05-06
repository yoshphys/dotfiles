local vim_config_path = vim.fn.fnamemodify(vim.fn.expand('<sfile>'), ':h')
vim.env.VIM_CONFIG_PATH = vim_config_path

vim.cmd("source " .. vim_config_path .. "/rc/vimrc.lua")
-- vim.cmd("source " .. vim_config_path .. "/rc/test.lua")
