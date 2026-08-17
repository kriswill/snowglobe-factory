# triggered by the gaming specialization from the installer
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.profiles.gaming;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.profiles.gaming = {
    enable = lib.mkEnableOption "utilities for that OOB Linux gaming experience";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # rgb control
        services.hardware.openrgb = {
          enable = slib.setDefault true;
          motherboard = config.snowglobe-factory.system.cpu-vendor;
        };

        hardware = {
          # just in case
          xone.enable = slib.setDefault true;
        };

        programs = {
          # open source frontend for managing your games and emulators
          lutris.enable = slib.setDefault true;

          # performance overlay
          mangohud.enable = slib.setDefault true;

          # install and manage proton versions
          protonup-qt.enable = slib.setDefault true;

          # autoclicker (this works in wayland as most games run in xwayland)
          xclicker.enable = slib.setDefault true;

          # proprietary garbage, but required for most modern gaming :(
          steam = {
            enable = slib.setDefault true;
            gamescopeSession = {
              enable = slib.setDefault true;
            };
            localNetworkGameTransfers.openFirewall = slib.setDefault true;
          };
        };
        # TODO gamemode
      }
    ]
  );
}
