local cache_path = vim.fn.stdpath('cache') .. "/goda-pm"
if vim.uv.fs_stat(cache_path) then
    vim.fn.system({ "mkdir", "-p", cache_path })
end
vim.env.GODA_PM_CACHE_PATH = cache_path

local function goda_pm_init_plugin(plugin)
    local dir = cache_path .. "/repos/github.com/" .. plugin
    if not vim.uv.fs_stat(dir) then
        vim.fn.system({ "git", "clone", "https://github.com/" .. plugin, dir })
    end
    vim.opt.runtimepath:append(dir)
end

goda_pm_init_plugin("Shougo/goda-pm.vim")
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
    for _, ext in ipairs({
        "Shougo/goda.vim",
        "Shougo/goda-pm-ext-lazy.vim",
    }) do
        goda_pm_init_plugin(ext)
    end

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

-- -- install
-- vim.api.nvim_create_user_command("GodaPmInstall",
--     function()
--         goda_pm.async_ext_action('installer', 'install')
--     end,
--     {}
-- )
--
-- -- update
-- vim.api.nvim_create_user_command("GodaPmUpdate",
--     function(opts)
--         local args = opts.fargs
--         goda_pm.async_ext_action('installer', 'update', { names = args })
--     end,
--     { nargs = "*" }
-- )
