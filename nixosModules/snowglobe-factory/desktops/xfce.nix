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
    environment.xfce.excludePackages = builtins.attrValues {
      inherit (pkgs)
        # prefer vlc as a media player
        parole
        ;
    };

    services.xserver = {
      enable = true;
      desktopManager.xfce = {
        enable = true;
      };
    };
  };
}
