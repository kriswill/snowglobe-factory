{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
  isUEFI = (config.snowglobe-factory.system.firmware == "UEFI");
in
{
  options.snowglobe-factory.boot-config.enable = lib.mkEnableOption "snowglobe-factory's grub configuration";

  config = lib.mkIf config.snowglobe-factory.boot-config.enable {
    boot = {
      loader = {
        # give the user more time to select configurations for slower monitors
        timeout = slib.setDefault 10;
        grub = {
          enable = true;
          efiSupport = isUEFI;
          memtest86.enable = slib.setDefault (
            (builtins.substring 0 3 config.nixpkgs.hostPlatform.system) == "x86"
          );
          devices = [ "nodev" ];
          gfxmodeEfi = slib.setDefault "1920x1080";
          gfxmodeBios = slib.setDefault "1920x1080";
          # cool looking grub theme
          theme = slib.setDefault pkgs.distro-grub-themes.nixos-grub-theme;
          extraEntries = ''
            menuentry "Reboot" {
              reboot
            }
            menuentry "Poweroff" {
              halt
            } 
          ''
          + lib.optionalString isUEFI ''
            menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' {
              fwsetup
            }
          '';
        };
      };
    };
  };
}
