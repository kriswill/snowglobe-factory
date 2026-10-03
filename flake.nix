{
  description = "Core modules for the NixOS snowglobes framework.";

  outputs =
    { nixpkgs, self, ... }:
    let
      flake = self;
      inputs = flake.inputs;
      outputs = flake.outputs;
      lib = nixpkgs.lib;
      import-tree = inputs.import-tree;

      perSystem =
        let
          systems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        in
        src:
        lib.genAttrs systems (
          system:
          import src {
            inherit flake;
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = builtins.attrValues outputs.overlays;
            };
          }
        );
    in
    {
      # expose custom functions for use with other flakes and projects
      lib = import ./lib/functions { inherit flake; };
      overlays = import ./overlays { inherit flake; };

      packages = perSystem ./packages;
      devShells = perSystem ./devshell.nix;
      formatter = perSystem ./formatter.nix;

      nixosConfigurations = import ./nixosConfigurations { inherit flake; };

      nixosModules = rec {
        snowglobe-factory = {
          imports = [
            (import-tree [
              ./nixosModules/snowglobe-factory
              { nixpkgs.overlays = builtins.attrValues outputs.overlays; }
              outputs.nixosModules.nixos
              # improved disk partition management
              inputs.disko.nixosModules.default

              # inputs.xlibre-overlay.nixosModules.overlay-xlibre-xserver
              # inputs.xlibre-overlay.nixosModules.overlay-all-xlibre-drivers
            ])
            # secrets storage and key management
            # does not work with import-tree for some reason
            inputs.sops-nix.nixosModules.default
          ];
        };
        # nixos module patches
        nixos = import-tree ./nixosModules/nixos;
        # expose the modules from nixos-hardware because they do not wrap them with options for some reason
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        default = snowglobe-factory;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:/nixos/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/NixOS/nixos-hardware/*.tar.gz";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
