{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.snowglobe-factory.gpu.intel;
in
{
  options.snowglobe-factory.gpu.intel.enable = mkEnableOption "snowglobe-factory's intel gpu configuration";
  config = mkIf cfg.enable {
    # provide hardware acceleration to most GPUs
    hardware.graphics.extraPackages = builtins.attrValues {
      inherit (pkgs)
        intel-media-driver
        intel-vaapi-driver
        ;
    };
  };
}
