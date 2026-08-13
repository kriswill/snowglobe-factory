{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.profiles.hardware-tools;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.profiles.hardware-tools.enable =
    lib.mkEnableOption "hardware diagnostic tools";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # corefreq does not build in nixpkgs-unstable 6-20-2026
        # programs.corefreq.enable = slib.setDefault true;
        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            usbutils
            smartmontools
            hdparm
            nvme-cli
            lm_sensors
            pciutils
            lshw
            hwinfo
            inxi
            vdpauinfo
            libva-utils
            mesa-demos
            vulkan-tools
            clinfo
            ;
        };
      }
    ]
  );
}
