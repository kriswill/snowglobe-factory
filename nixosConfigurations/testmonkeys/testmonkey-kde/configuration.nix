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
      kde.enable = true;
    };
  };
}
