{ flake }:
let
  inputs = flake.inputs;
  outputs = flake.outputs;
  lib = inputs.nixpkgs.lib;
  slib = outputs.lib;
in
{
  hostname ? "nixos", # name your system
  firmware ? "UEFI", # firmware implementation, one of UEFI or BIOS
  cpu-vendor ? null, # cpu vendor, "intel" or "amd"
  gpu-vendors ? [ ], # list of gpu vendors, "intel" "nvidia" "amd"
  isVM ? false, # are we in a VM?
  stateVersion ? "26.11", # initial release of nixos which this machine was installed
  system ? "x86_64-linux", # target cpu architecture
  modules ? [ ], # send extra modules to the function
  nixImplementation ? "lix", # which implementation of nix to use: nix for cppnix, or lix
  specialArgs ? { }, # send extra special arguments to the function
  configDir ? null,
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  lix-stable = pkgs.lixPackageSets.stable.lix;
in
lib.nixosSystem {
  inherit system; # used for legacy nixos < 22.05, but it doesn't hurt to have it here
  inherit specialArgs;
  modules =
    let
      configDirExists = ((configDir != null) && (builtins.pathExists configDir));
      hostConfig = if configDirExists then inputs.import-tree configDir else { };
    in
    [ outputs.nixosModules.default ]
    ++ [
      {
        snowglobe-lib.enable = slib.setDefault true;
        nixpkgs.hostPlatform = system;

        # set secrets file
        sops.defaultSopsFile = lib.mkIf configDirExists (slib.setDefault "${configDir}/secrets.yaml");

        # populate system options with hardware specific config
        system = {
          inherit stateVersion;
        };
        networking.hostName = hostname;
        snowglobe-lib.system = {
          inherit
            cpu-vendor
            gpu-vendors
            isVM
            firmware
            ;
        };

        assertions = [
          {
            assertion = (
              nixImplementation == "nix" || nixImplementation == "lix" || nixImplementation == "lix-main"
            );
            message = "slib.mkNixosHost: nixImplementation must be one of 'nix' or 'lix'";
          }
        ];
      }
    ]
    # if 'nix' then do nothing
    ++ lib.optionals (nixImplementation == "lix-main") [
      {
        # import lix module. Will be rolling release of lix
        imports = [ inputs.lix-module.nixosModules.default ];
      }
    ]
    ++ lib.optionals (nixImplementation == "lix") [
      {
        # replace 'nix' in nixpkgs to be lix via overlay so all tooling will be compatible with it.
        nix.package = lix-stable;
        nixpkgs.overlays = [
          (final: prev: {
            nix = lix-stable;
          })
        ];
      }
    ]
    ++ [ hostConfig ]
    # extra modules passed to the function
    ++ modules;
}
