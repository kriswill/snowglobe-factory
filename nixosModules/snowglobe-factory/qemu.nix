{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "qemu";
  cfg = config.snowglobe-factory.${module-name};
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.${module-name} = {
    enable = lib.mkEnableOption "OOB configuration for qemu running under libvirtd for use with virt-manager.";
  };

  # configuration mostly taken from https://wiki.nixos.org/wiki/Virt-manager
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ pkgs.dnsmasq ];
        boot.kernelModules =
          let
            cpu-vendor = config.snowglobe-factory.system.cpu-vendor;
          in
          lib.mkIf (cpu-vendor != null) [ "kvm-${cpu-vendor}" ];

        virtualisation = {
          libvirtd = {
            enable = true;
            qemu = {
              # allow emulating TPM in qemu
              swtpm.enable = true;
              # use kvm as for hypervisor
              package = slib.setDefault pkgs.qemu_kvm;
              # fix for: https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/6
              vhostUserPackages = [ pkgs.virtiofsd ];
            };
          };
        };
      }
      (lib.mkIf (config.snowglobe-factory.desktop.enable) {
        programs.virt-manager.enable = slib.setDefault true;
      })
    ]
  );
}
