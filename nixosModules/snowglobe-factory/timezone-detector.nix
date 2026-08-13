{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.timezone-detector;
  cfgs = config.services;
in
{
  options.snowglobe-factory.timezone-detector = {
    enable = lib.mkEnableOption "Module to automatically detect and set the timezone based on your geolocation. Uses services.tzupdate.";
    dispatcherTimeout = lib.mkOption {
      description = "time in seconds that tzupdate should spend querying the api servers from the networkmanager dispatcher script before giving up.";
      type = lib.types.int;
      default = 10;
    };
  };

  config = lib.mkIf cfg.enable {
    # provide the utility to the system PATH
    environment.systemPackages = [ pkgs.tzupdate ];

    # use networkmanager to set the timezone when the network connectivity updates
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeText "update-timezone" ''
          case "$2" in
            "connectivity-change")
              timedatectl set-timezone "$(${pkgs.tzupdate}/bin/tzupdate -p -s ${toString cfg.dispatcherTimeout})" || exit 1
              ;;
          esac
        '';
      }
    ];
  };
}
