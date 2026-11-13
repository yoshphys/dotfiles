local cache_path = vim.fn.stdpath('cache') .. "/goda-pm"
if vim.uv.fs_stat(cache_path) then
    vim.fn.system({ "mkdir", "-p", cache_path })
end
vim.env.GODA_PM_CACHE_PATH = cache_path

-- Needed here (not just in neovim.rc.lua) because this file uses the group
-- below, before neovim.rc.lua is sourced via InlineVimrcs during load_state.
vim.api.nvim_create_augroup("MyAutoCmd", {})

local function goda_pm_init_plugin(plugin)
    local dir = cache_path .. "/repos/github.com/" .. plugin
    if not vim.uv.fs_stat(dir) then
        vim.fn.system({ "git", "clone", "https://github.com/" .. plugin, dir })
    end
    vim.opt.runtimepath:append(dir)
end

goda_pm_init_plugin("Shougo/goda-pm.vim")
-- goda.vim's goda#register() is needed by goda_pm.vim itself whenever it
-- talks to the Go binary (make_state/install/update), not just on a cold
-- bootstrap, so it must always be on runtimepath, unlike goda-pm-ext-lazy.vim
-- (which is loaded eagerly from the generated state once it exists).
goda_pm_init_plugin("Shougo/goda.vim")
local goda_pm = require("goda_pm")

vim.g["goda_pm#config_dir"] = vim.env.VIM_CONFIG_PATH .. "/rc/goda-pm"

local load_state_failed = goda_pm.load_state(cache_path)

-- nvimバージョン/ビルドが変わったらstateを自動クリア (load_state後なのでdpp初期化済み)
local version_file   = cache_path .. "/nvim_version"
local current_version = vim.fn.execute("version"):match("NVIM%s+(%S+)")
local current_progpath = vim.v.progpath
local version_changed  = false
local stored_version, stored_progpath
local vf = io.open(version_file, "r")
if vf then
    stored_version  = vf:read("*l")
    stored_progpath = vf:read("*l")
    vf:close()
    version_changed = stored_version ~= current_version
                   or stored_progpath ~= current_progpath
end
local wf = io.open(version_file, "w")
if wf then
    wf:write(current_version .. "\n" .. current_progpath)
    wf:close()
end

if load_state_failed or version_changed then
    if version_changed then
        goda_pm.clear_state()
    end
    goda_pm_init_plugin("Shougo/goda-pm-ext-lazy.vim")

    local reason
    if not version_changed then
        reason = "state not found or invalid"
    elseif stored_version ~= current_version then
        reason = string.format("version: %s → %s", stored_version, current_version)
    else
        reason = string.format("build changed (same %s)", current_version)
    end
    local warn_msg = string.format(
        "dpp: load_state failed (%s)\nexe: %s",
        reason,
        current_progpath
    )

    vim.api.nvim_create_autocmd("User", {
        group = "MyAutoCmd",
        pattern = "VimEnter",
        callback = function()
            vim.notify(warn_msg, vim.log.levels.WARN)
            goda_pm.make_state(cache_path)
        end,
    })
-- else
--     vim.api.nvim_create_autocmd("BufWritePost", {
--         group = "MyAutoCmd",
--         pattern = vim.env.VIM_CONFIG_PATH .. "/**/*",
--         callback = function()
--             dpp.check_files()
--         end,
--     })
--     vim.api.nvim_create_autocmd("BufWritePost", {
--         pattern = vim.env.VIM_CONFIG_PATH .. "/rc/toml/*.toml",
--         callback = function()
--             local not_installed = dpp.sync_ext_action("installer", "getNotInstalled")
--             if not vim.tbl_isempty(not_installed) then
--                 dpp.async_ext_action("installer", "install")
--             end
--         end,
--     })
end

vim.api.nvim_create_autocmd("User", {
    pattern = "GodaPm:makeStatePost",
    callback = function()
        vim.notify("dpp make_state() is done")
    end,
})

vim.cmd("filetype indent plugin on") -- necessary for specific settings according to filetype
-- vim.cmd("syntax on")

-- clear (for debug)
vim.api.nvim_create_user_command("GodaPmClearState",
    function()
        goda_pm.clear_state()
    end,
    {}
)

-- make state (for debug)
vim.api.nvim_create_user_command("GodaPmMakeState",
    function()
        goda_pm.make_state(cache_path)
    end,
    {}
)

-- Force-rebuild the Go binary from main.go. goda-pm.vim normally rebuilds
-- automatically when main.go is newer than the cached binary, but every
-- file under $VIM_CONFIG_PATH is deployed read-only from the Nix store
-- (mtime fixed at the epoch), so that staleness check never fires here;
-- run this explicitly after editing rc/goda-pm/main.go.
vim.api.nvim_create_user_command("GodaPmBuild",
    function()
        goda_pm.build()
    end,
    {}
)

-- NOTE: GodaPmInstall/GodaPmUpdate are defined in goda.toml's
-- "Shougo/goda-pm.vim" entry's lua_add hook, not here.
