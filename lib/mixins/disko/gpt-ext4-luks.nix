# password based luks encryption for legacy bios
{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # CHANGE BEFORE FORMATTING
        device = "/dev/sda";
        content = {
          # use a GPT disk for all systems
          type = "gpt";
          partitions = {
            # required for legacy bios / CSM mode to boot drives with GPT via grub
            bios_grub = {
              name = "BIOS_GRUB";
              type = "EF02";
              size = "1M";
            };
            esp = {
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # ensure that boot is only accessible by root
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "ROOT";
                settings.allowDiscards = true;
                # text file containing the password (only needed when formatting, handled by installer)
                passwordFile = "/tmp/luks-password";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
