{
  pkgs,
  lib,
  config,
  flake,
  ...
}:
{
  snowglobe-factory = {
    desktop = {
      xfce.enable = true;
    };
  };
}
