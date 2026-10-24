{ flake }:
let
  inputs = flake.inputs;
  outputs = flake.outputs;
  lib = inputs.nixpkgs.lib;
  slib = outputs.lib;
in
{
  snowglobe-installer-x86_64 = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
  };

  snowglobe-installer-x86_64-untrusted = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
    modules = [
      {
        substituters."nix-store.earthgman.dev".enable = false;
        environment.sessionVariables.CACHE_UNTRUSTED = "1";
      }
    ];
  };

  snowglobe-installer-x86_64-small = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
    modules = [
      {
        hardware = {
          enableRedistributableFirmware = lib.mkForce false;
          enableAllFirmware = lib.mkForce false;
        };
      }
    ];
  };

  snowglobe-installer-x86_64-small-untrusted = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
    modules = [
      {
        substituters."nix-store.earthgman.dev".enable = false;
        environment.sessionVariables.CACHE_UNTRUSTED = "1";
        hardware = {
          enableRedistributableFirmware = lib.mkForce false;
          enableAllFirmware = lib.mkForce false;
        };
      }
    ];
  };

  testmonkey-default = slib.mkNixosHost {
    hostname = "testmonkey";
    system = "x86_64-linux";
    configDir = ./testmonkeys/testmonkey-default;
    specialArgs = { inherit flake; };
  };

  testmonkey-xfce = slib.mkNixosHost {
    hostname = "testmonkey-xfce";
    system = "x86_64-linux";
    configDir = ./testmonkeys/testmonkey-xfce;
    specialArgs = { inherit flake; };
  };

  testmonkey-kde = slib.mkNixosHost {
    hostname = "testmonkey-kde";
    system = "x86_64-linux";
    configDir = ./testmonkeys/testmonkey-kde;
    specialArgs = { inherit flake; };
  };
}
