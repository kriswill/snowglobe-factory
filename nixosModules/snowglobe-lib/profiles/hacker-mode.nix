# basically turns nixos into kali linux
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.hacker-mode;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.hacker-mode.enable =
    lib.mkEnableOption "Snowglobe-Lib's cybersecurity suite. Installs a majority of tools present on Kali.";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (config.snowglobe-lib.desktop.enable) {
        programs = {
          ghidra.enable = slib.setDefault true;
          zenmap.enable = slib.setDefault true;
          tor-browser.enable = slib.setDefault true;
          wireshark.package = slib.setDefault pkgs.wireshark; # install gui version if desktop is enabled
        };
      })
      {
        services = {
          tor = {
            enable = slib.setDefault true;
            enableGeoIP = slib.setDefault false;
            client.enable = slib.setDefault true;
            torsocks.enable = slib.setDefault true;
          };
        };

        programs = {
          tcpdump.enable = slib.setDefault true;
          metasploit.enable = slib.setDefault true;
          lynx.enable = slib.setDefault true;
          binsider.enable = slib.setDefault true;
          wireshark.enable = slib.setDefault true;
          traceroute.enable = slib.setDefault true;
          nmap.enable = slib.setDefault true;
          john.enable = slib.setDefault true;
        };

        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            binutils
            dnsutils
            ;
        };
      }
    ]
  );
}
