{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.profiles.nix-tools;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-factory.profiles.nix-tools = {
    enable = lib.mkEnableOption "tools for development with nix";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      direnv.enable = slib.setDefault true;
    };

    # TODO maybe make all of these into program options?
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        nurl
        nix-prefetch-git
        deadnix
        nixpkgs-hammering
        statix
        nix-init
        nix-update
        nixpkgs-review
        nixfmt
        ;
    };
  };
}
