{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-factory.gpu.amd;
in
{
  options.snowglobe-factory.gpu.amd.enable = lib.mkEnableOption "snowglobe-factory's amdgpu configuration";
  config = lib.mkIf cfg.enable {
    services = {
      xserver.videoDrivers = [ "amdgpu" ];
    };

    hardware = {
      # allow overclocking
      amdgpu.overdrive.enable = slib.setDefault true;
      # enable full resolution during early KMS while booting
      amdgpu.initrd.enable = slib.setDefault true;
    };
  };
}
