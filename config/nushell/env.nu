# env.nu

$env.LANG = "en_US.UTF-8"
$env.XDG_CONFIG_HOME = ($env.HOME + '/.config')
$env.XDG_CACHE_HOME = ($env.HOME + '/.cache')
$env.XDG_DATA_HOME = ($env.HOME + '/.local/share')
$env.XDG_STATE_HOME = ($env.HOME + '/.local/state')
$env.EDITOR = 'nvim'
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"

$env.PATH = ($env.PATH | prepend [
    ($env.HOME + "/utilities/bin") # user software
    ($env.HOME + "/.cargo/bin") # rust
    ($env.HOME + "/zk-lsp/tools") # zk-lsp
    ($env.HOME + "/.julia/bin") # julia apps
] | uniq)

# Rex adds its CLI to the PATH of the terminals it opens, but nix-darwin rebuilds
# PATH from a fixed list on every shell start and drops it. Re-add it here. The
# variable is empty outside Rex, so guard it rather than prepending blindly,
# which would leave an empty PATH entry.
if ($env.REX_BIN_DIR? | is-not-empty) {
    $env.PATH = ($env.PATH | prepend $env.REX_BIN_DIR)
}

$env.MOCWORD_DATA = ($env.HOME + '/.mocword/mocword.sqlite')

# Load API keys from ~/.apikeys so they're available in non-interactive sessions too
let _apikeys_path = ($env.HOME + '/.apikeys')
if ($_apikeys_path | path exists) {
    open $_apikeys_path
    | lines
    | where { |line| ($line | str trim) != "" and not ($line | str starts-with "#") }
    | parse -r '^\s*(?P<key>\S+)\s+(?P<value>.+)'
    | each { |row| { ($row.key): ($row.value | str trim | str trim --char '"') } }
    | into record
    | load-env
}
