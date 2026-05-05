# env.nu

$env.LANG = "en_US.UTF-8"
$env.XDG_CONFIG_HOME = ($env.HOME + '/.config')
$env.XDG_DATA_HOME = ($env.HOME + '/.local/share')
$env.XDG_CACHE_HOME = ($env.HOME + '/.cache')
$env.EDITOR = 'nvim'
$env.MANPAGER = "sh -c 'col -bx | bat -p -lman'"

$env.PATH = ($env.PATH | prepend [
    ($env.HOME + "/utilities/bin") # user software
    ($env.HOME + "/.cargo/bin") # rust
    ($env.HOME + "/zk-lsp/tools") # zk-lsp
    ($env.HOME + "/.juliaup/bin") # julia
    ($env.HOME + "/.julia/bin") # jetls
] | uniq)
