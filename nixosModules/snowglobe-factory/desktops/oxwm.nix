{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop.oxwm;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.desktop.oxwm.enable =
    lib.mkEnableOption "snowglobe-factory's oxwm module";

  config = lib.mkIf cfg.enable {
    snowglobe-factory.system.hasDesktop = lib.mkForce true;
    snowglobe-factory.desktop = {
      enable = lib.mkForce true;
    };
    programs = {
      # default terminal
      alacritty.enable = slib.setDefault true;
    };
    services.xserver = {
      enable = true;
      windowManager.oxwm.enable = true;
    };
  };
}
