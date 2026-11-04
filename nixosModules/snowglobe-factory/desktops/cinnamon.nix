{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop.cinnamon;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.desktop.cinnamon.enable =
    lib.mkEnableOption "snowglobe-factory's cinnamon desktop module";

  config = lib.mkIf cfg.enable {
    snowglobe-factory = {
      desktop.enable = true;
    };

    programs.vlc.enable = slib.overrideDefault false;

    services.xserver = {
      enable = true;
      desktopManager.cinnamon = {
        enable = true;
      };
    };
  };
}
