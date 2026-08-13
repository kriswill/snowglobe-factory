{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-factory.gpu.nvidia;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.gpu.nvidia = {
    enable = lib.mkEnableOption "snowglobe-factory's nvidia gpu configuration";
  };
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = slib.setDefault true;

      powerManagement.enable = slib.setDefault true;

      # use open for RTX 20 series or newer
      # TODO some way to detect old cards which this does not work
      open = slib.setDefault true;
      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`
      nvidiaSettings = lib.mkIf config.snowglobe-factory.desktop.enable (slib.setDefault true);

      # latest stable nvidia drivers
      # nvidia loves dropping support for old cards, a manual override might be required
      package = slib.setDefault config.boot.kernelPackages.nvidiaPackages.production;
    };
  };
}
