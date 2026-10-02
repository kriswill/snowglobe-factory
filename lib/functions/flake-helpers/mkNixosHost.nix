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
  specialArgs ? { }, # send extra special arguments to the function
  configDir ? null,
}:
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
        snowglobe-factory.enable = slib.setDefault true;
        nixpkgs.hostPlatform = system;

        # set secrets file
        sops.defaultSopsFile = lib.mkIf configDirExists (slib.setDefault "${configDir}/secrets.yaml");

        system = {
          inherit stateVersion;
        };
        networking.hostName = hostname;
        snowglobe-factory.system = {
          inherit
            cpu-vendor
            gpu-vendors
            isVM
            firmware
            ;
        };
      }
    ]
    ++ [ hostConfig ]
    # extra modules passed to the function
    ++ modules;
}
