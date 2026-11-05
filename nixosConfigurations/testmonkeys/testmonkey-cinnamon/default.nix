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
      cinnamon.enable = true;
    };
  };
}
