{ ... } @ inputs: {
  nix = {
    enable = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    package = inputs.nix-monitored.packages.${inputs.pkgs.system}.default;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "${inputs.username}" ];
    };
  };

  nixpkgs.hostPlatform = inputs.system;
  users.users.${inputs.username} = {
    home = "/Users/${inputs.username}";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks = inputs.brewCasks;
  };

  system = {
    stateVersion = 5;

    primaryUser = inputs.username;

    defaults = {
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
      LaunchServices.LSQuarantine = false;
      NSGlobalDomain.AppleShowAllExtensions = true;
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        _FXShowPosixPathInTitle = true;
      };
      dock = {
        orientation = "bottom";
        autohide = true;
        show-recents = false;
        launchanim = false;
      };
    };
  };

  security = {
    pam.services.sudo_local.touchIdAuth = true;
  };
}
