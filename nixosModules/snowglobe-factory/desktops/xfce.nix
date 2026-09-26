{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop.xfce;
in
{
  options.snowglobe-factory.desktop.xfce.enable =
    lib.mkEnableOption "snowglobe-factory's xfce desktop module";

  config = lib.mkIf cfg.enable {
    snowglobe-factory = {
      desktop.enable = true;
      system.hasDesktop = lib.mkForce true;
    };
    services.xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };
  };
}
