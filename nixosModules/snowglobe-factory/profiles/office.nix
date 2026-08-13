{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.profiles.office;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.profiles.office = {
    enable = lib.mkEnableOption "tools and programs typically found in an office setting";
  };

  config = lib.mkIf cfg.enable {
    # enable a working local print server by default
    snowglobe-factory.cups.enable = slib.setDefault true;

    programs = {
      # email client
      thunderbird.enable = slib.setDefault true;
      # open source MSoffice
      libreoffice.enable = slib.setDefault true;
      # scanning software
      simple-scan.enable = slib.setDefault true;
      # ftp client
      filezilla.enable = slib.setDefault true;
      # easily convert image formats
      switcheroo.enable = slib.setDefault true;
    };
  };
}
