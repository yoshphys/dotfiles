{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    flatten
    mkEnableOption
    mkIf
    mkOption
    splitString
    types
    ;
  cfg = config.services.yaskkserv2;
  isDarwin = pkgs.stdenv.isDarwin;
  cacheDir = "${config.xdg.cacheHome}/yaskkserv2";
in
{
  options.services.yaskkserv2 = {
    enable = mkEnableOption "yaskkserv2 SKK server";
    package = mkOption {
      type = types.package;
      default = pkgs.yaskkserv2;
    };
    dictionary = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/skk/dictionary.yaskkserv2";
      description = "Path to the yaskkserv2 binary dictionary (built by yaskkserv2_make_dictionary)";
    };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [
        "--google-japanese-input notfound"
        "--google-cache-filename=${cacheDir}/google.cache"
      ];
    };
  };

  config = mkIf cfg.enable {
    home.file."utilities/bin/make-yaskkserv2-dict" = {
      source = ../../../scripts/make-yaskkserv2-dict.nu;
      executable = true;
    };

    home.activation.yaskkserv2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${cacheDir}"
    '';

    launchd.agents.yaskkserv2 = mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/yaskkserv2"
          "--no-daemonize"
        ]
        ++ flatten (map (x: splitString " " x) cfg.extraArgs)
        ++ [ cfg.dictionary ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/yaskkserv2/stdout";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/yaskkserv2/stderr";
      };
    };

    systemd.user.services.yaskkserv2 = mkIf (!isDarwin) {
      Unit.Description = "yaskkserv2 SKK server";
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/yaskkserv2 --no-daemonize ${lib.concatStringsSep " " cfg.extraArgs} ${cfg.dictionary}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
