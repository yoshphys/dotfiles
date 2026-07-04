-- lua_add {{{
-- user templates take precedence over the bundled ones (searched first)
vim.g.sonictemplate_vim_template_dir = { vim.env.VIM_CONFIG_PATH .. "/template" }
-- }}}
