{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-factory.gpu;
  moduleEnabled = (cfg.amd.enable || cfg.nvidia.enable || cfg.intel.enable);
in
{
  config = lib.mkIf moduleEnabled {
    hardware.graphics.enable = true;
    # good tool for monitoring and control of your gpu
    services.lact.enable =
      let
        cfgp = config.snowglobe-factory.profiles;
      in
      slib.setDefault (cfgp.hardware-tools.enable || cfgp.gaming.enable);
  };
}
