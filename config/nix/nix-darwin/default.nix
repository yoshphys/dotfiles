{ ... } @ inputs: {
  nix = {
    enable = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    package = inputs.nix-monitored.packages.${inputs.system}.default;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "${inputs.username}" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
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
      extraFlags = [
        "--force-cleanup"
      ];
    };
    casks = inputs.brewCasks;
    taps = inputs.brewTaps;
    brews = inputs.brewFormulas;
  };

  system = {
    stateVersion = 6;

    primaryUser = inputs.username;

    defaults = {
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
      LaunchServices.LSQuarantine = false;
      NSGlobalDomain.AppleShowAllExtensions = true;
      finder = {
        AppleShowAllFiles = false;
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
