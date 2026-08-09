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
        snowglobe-lib = {
          imports = [
            (import-tree [
              ./nixosModules/snowglobe-lib
              { nixpkgs.overlays = builtins.attrValues outputs.overlays; }
              outputs.nixosModules.nixos
              # improved disk partition management
              inputs.disko.nixosModules.default
              # queue system for nix post-build-hook when uploading to binary caches
              inputs.nix-post-build-hook-queue.nixosModules.default
              # project providing cli indexing
              inputs.nix-index-database.nixosModules.default
              # lix
              inputs.lix-module.nixosModules.default
              # provides many rolling release packages
              inputs.chaotic.nixosModules.default
            ])
            # secrets storage and key management
            # does not work with import-tree for some reason
            inputs.sops-nix.nixosModules.default
          ];
        };
        # nixos module patches
        nixos = import-tree ./nixosModules/nixos;
        # jovian configuration
        jovian = import ./nixosModules/jovian { inherit flake; };
        # expose the modules from nixos-hardware because they do not wrap them with options for some reason
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        default = snowglobe-lib;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:/nixos/nixpkgs/nixos-26.05";

    chaotic = {
      url = "github:chaotic-cx/nyx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flux = {
      url = "github:iogamaster/flux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/NixOS/nixos-hardware/*.tar.gz";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-post-build-hook-queue = {
      url = "github:newam/nix-post-build-hook-queue";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt.follows = "";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
