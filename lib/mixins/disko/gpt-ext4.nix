# unencrypted disko with just a boot and root partition
{
  disko.devices = {
    disk = {
      # disk label
      nixos = {
        # CHANGE PATH BEFORE FORMATTING (done by the installer)
        device = "/dev/sda";
        type = "disk";
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
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # ensure that boot is only accessible by root
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              name = "ROOT";
              size = "100%";
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
}
