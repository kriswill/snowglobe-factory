{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop.labwc;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.desktop.labwc.enable = lib.mkEnableOption "snowglobe-factory's labwc module";

  config = lib.mkIf cfg.enable {
    snowglobe-factory.system.hasDesktop = lib.mkForce true;
    snowglobe-factory.desktop = {
      enable = lib.mkForce true;
      installWaylandDeps = true;
    };
    programs = {
      labwc = {
        enable = true;
        withUWSM = slib.setDefault true;
      };
      # default terminal
      foot.enable = slib.setDefault true;
      # applications and dmenu
      rofi.enable = slib.setDefault true;
      # Default shell - noctalia v5
      noctalia = {
        enable = slib.setDefault true;
        systemd.enable = slib.setDefault true;
      };
    };
  };
}
