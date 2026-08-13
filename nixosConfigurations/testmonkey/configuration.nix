# configuration that enables as many things as possible
# so the ci.sh can cache to nix-store.earthgman.dev and check nixpkgs for failing builds
{
  pkgs,
  lib,
  config,
  flake,
  ...
}:
let
  mkForce = lib.mkForce;
  outputs = flake.outputs;
  enableAllModules =
    moduleType:
    let
      moduleNames = (builtins.attrNames (builtins.readDir ../../nixosModules/nixos/${moduleType}));
    in
    lib.genAttrs moduleNames (module: {
      enable = true;
    });
in
{
  programs = enableAllModules "programs";
  services = enableAllModules "services";

  # build decky and other jovian plugins
  imports = [ outputs.nixosModules.jovian ];
  jovian.steam = {
    user = "bob";
    desktopSession = "niri";
  };

  snowglobe-factory = {
    gpu = {
      amd.enable = mkForce true;
      intel.enable = mkForce true;
      nvidia.enable = mkForce true;
    };
    desktop = {
      niri.enable = true;
      labwc.enable = true;
      # kde.enable = true;
      hyprland.enable = true;
    };
    qemu.enable = true;
    profiles = {
      office.enable = true;
      hacker-mode.enable = true;
      hardware-tools.enable = true;
      nix-tools.enable = true;
      gaming.enable = true;
    };
  };

  hardware.enableAllFirmware = true;

  # add all custom packages
  environment.systemPackages = lib.forEach (builtins.attrNames (
    import ../../packages {
      inherit flake pkgs;
    }
  )) (package: pkgs.${package});
}
