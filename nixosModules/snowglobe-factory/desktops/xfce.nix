{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop.xfce;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.desktop.xfce.enable =
    lib.mkEnableOption "snowglobe-factory's xfce desktop module";

  config = lib.mkIf cfg.enable {
    snowglobe-factory = {
      desktop.enable = true;
    };

    programs.vlc.enable = slib.overrideDefault false;

    services.xserver = {
      enable = true;
      desktopManager.xfce = {
        enable = true;
      };
    };
  };
}
