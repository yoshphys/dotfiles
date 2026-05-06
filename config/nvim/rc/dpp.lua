local cache_path = os.getenv("HOME") .. "/.cache/dpp"
vim.env.DPP_CACHE_PATH = cache_path

local function dpp_init_plugin(plugin)
    local dir = cache_path .. "/repos/github.com/" .. plugin
    if not vim.uv.fs_stat(dir) then
        vim.fn.system({ "git", "clone", "https://github.com/" .. plugin, dir })
    end
    vim.opt.runtimepath:append(dir)
end

dpp_init_plugin("Shougo/dpp.vim")
local dpp = require("dpp")


local dpp_config = "$VIM_CONFIG_PATH/rc/ts/dpp.ts"

local load_state_failed = dpp.load_state(cache_path)

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
        dpp.clear_state()
    end
    for _, ext in ipairs({
        "Shougo/dpp-ext-installer",
        "Shougo/dpp-ext-toml",
        "Shougo/dpp-ext-lazy",
        "Shougo/dpp-protocol-git",
        "vim-denops/denops.vim",
    }) do
        dpp_init_plugin(ext)
    end

    -- vim.cmd("runtime! plugin/denops.vim")

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
        pattern = "DenopsReady",
        callback = function()
            vim.notify(warn_msg, vim.log.levels.WARN)
            dpp.make_state(cache_path, dpp_config)
        end,
    })
else
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = "MyAutoCmd",
        pattern = vim.env.VIM_CONFIG_PATH .. "/**/*",
        callback = function()
            dpp.check_files()
        end,
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = vim.env.VIM_CONFIG_PATH .. "/rc/toml/*.toml",
        callback = function()
            local not_installed = dpp.sync_ext_action("installer", "getNotInstalled")
            if not vim.tbl_isempty(not_installed) then
                dpp.async_ext_action("installer", "install")
            end
        end,
    })
end

vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:makeStatePost",
    callback = function()
        vim.notify("dpp make_state() is done")
    end,
})

vim.cmd("filetype indent plugin on") -- necessary for specific settings according to filetype
-- vim.cmd("syntax on")

-- clear (for debug)
vim.api.nvim_create_user_command("DppClearState",
    function()
        dpp.clear_state()
    end,
    {}
)

-- make state (for debug)
vim.api.nvim_create_user_command("DppMakeState",
    function()
        dpp.make_state(cache_path, dpp_config)
    end,
    {}
)

-- install
vim.api.nvim_create_user_command("DppInstall",
    function()
        dpp.async_ext_action('installer', 'install')
    end,
    {}
)

-- update
vim.api.nvim_create_user_command("DppUpdate",
    function(opts)
        local args = opts.fargs
        dpp.async_ext_action('installer', 'update', { names = args })
    end,
    { nargs = "*" }
)
