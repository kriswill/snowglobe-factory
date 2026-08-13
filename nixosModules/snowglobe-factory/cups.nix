# reference https://nixos.wiki/wiki/Printing

{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-factory.cups;
in
{
  options.snowglobe-factory.cups = {
    enable = lib.mkEnableOption "snowglobe-factory's cups printing configuration.";
    installCommonDrivers = lib.mkOption {
      description = "Whether to install drivers for common printer models (open source drivers only)";
      type = lib.types.bool;
      default = true;
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      # enable scanning of nearby network printers that support IPP
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      # enable the cups server
      printing = {
        enable = slib.setDefault true;
        # provide some drivers by default for common printer models
        # does not include any proprietary drivers.
        drivers = lib.mkIf cfg.installCommonDrivers (
          builtins.attrValues {
            inherit (pkgs)
              # generic
              gutenprint
              # hp printers
              hplip
              # samsung printers
              splix
              # brother printers
              brlaser
              # epson printers
              epson-escpr
              epson-escpr2
              ;
          }
        );
      };
    };
  };
}
