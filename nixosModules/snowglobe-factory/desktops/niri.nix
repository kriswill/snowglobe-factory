# ensures all the default stuff that niri expects is installed
{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-factory.desktop.niri;
in
{
  options.snowglobe-factory.desktop.niri = {
    enable = lib.mkEnableOption "snowglobe-factory's niri configuration.";
  };

  config = lib.mkIf cfg.enable {
    snowglobe-factory.system.hasDesktop = lib.mkForce true;
    # shared desktop configuration
    snowglobe-factory.desktop = {
      enable = true;
      installWaylandTools = true;
    };

    services.polkit-gnome.enable = slib.setDefault true;

    programs = {
      niri = {
        enable = true;
        useNautilus = slib.setDefault true;
      };

      # default terminal
      alacritty.enable = slib.setDefault true;

      # default picker
      fuzzel.enable = slib.setDefault true;

      # default bar
      waybar = {
        enable = slib.setDefault true;
        # prevent 2 waybars from showing up due to niri's default config
        systemd.enable = slib.setDefault false;
      };

      # default xwayland implementation for niri
      xwayland-satellite.enable = slib.setDefault true;
    };
  };
}
