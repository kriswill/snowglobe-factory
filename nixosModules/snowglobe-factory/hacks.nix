# TODO check up on this file every once in awhile
{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  config = lib.mkIf config.snowglobe-factory.enable {
    # force polkit soteria to tear itself down properly on sessions not using uwsm like Niri
    systemd.user.services.polkit-soteria = lib.mkIf config.security.soteria.enable ({
      unitConfig = {
        Requisite = [ "graphical-session.target" ];
      };
    });
  };
}
