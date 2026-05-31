# config.nu

##################################################
## aliases

alias root = ^root -l


##################################################
## custom commands

def minvim [] {
  nvim -u ($env.HOME | path join ".config/minvim/init.lua")
}

def testnvim [...args] {
  with-env { XDG_CONFIG_HOME: ($env.HOME + "/dotfiles/config") } { nvim ...$args }
}

def --env sd [] {
  let dir = (ghq list --full-path | peco | str trim)
  if $dir != "" { cd $dir }
}

def --env load-apikeys [] {
     open ($env.HOME + "/.apikeys")
     | lines
     | where { |line| ($line | str trim) != "" and not ($line | str starts-with "#") }
     | parse -r '^\s*(?P<key>\S+)\s+(?P<value>.+)'
     | each { |row| { ($row.key): ($row.value | str trim | str trim --char '"') } }
     | into record
     | load-env
}
