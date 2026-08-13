{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.profiles.harden;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.profiles.harden = {
    enable = lib.mkEnableOption "snowglobe-factory's hardening configuration for increased system security";
  };

  config = lib.mkIf cfg.enable {
    # TODO research hardened kernels
    # boot.kernelPackages = slib.overrideDefault pkgs.linuxPackages_hardened;

    # prevent users from being imperatively modified
    users.mutableUsers = slib.setDefault false;

    # prevent password login over ssh
    services = {
      openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
