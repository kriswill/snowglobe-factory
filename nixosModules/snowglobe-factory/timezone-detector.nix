{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.timezone-detector;
in
{
  options.snowglobe-factory.timezone-detector = {
    enable = lib.mkEnableOption "Module to automatically detect and set the timezone based on your geolocation.";
    server = lib.mkOption {
      description = "API server to use";
      type = lib.types.str;
      default = "https://ipapi.co/timezone";
    };
  };

  config = lib.mkIf cfg.enable {
    # use networkmanager to set the timezone when the network connectivity updates
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeText "update-timezone" ''
          case "$2" in
            "connectivity-change")
              timedatectl set-timezone "$(${pkgs.curl}/bin/curl --fail ${cfg.server})"
              ;;
          esac
        '';
      }
    ];
  };
}
