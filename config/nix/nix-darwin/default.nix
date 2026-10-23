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

    activationScripts.postActivation.text = ''
      # pbs caches the Services list, including their shortcuts. Activation runs
      # as root, but the Services status lives in the user's own preferences.
      sudo -u ${inputs.username} /System/Library/CoreServices/pbs -flush || true
    '';

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
      # Keyboard shortcut for the edit-in-app service. @ = cmd, ~ = opt,
      # ^ = ctrl, $ = shift. The key is the service's own identifier, as the
      # Services system spells it.
      CustomUserPreferences.pbs.NSServicesStatus = {
        "(null) - Write in nvim - runWorkflowAsService" = {
          enabled_context_menu = 1;
          enabled_services_menu = 1;
          key_equivalent = "@~^n";
        };
      };
    };
  };

  security = {
    pam.services.sudo_local = {
      touchIdAuth = true;
      # pam_reattach: allow Touch ID inside persistent session managers (herdr, tmux)
      reattach = true;
    };
  };
}
