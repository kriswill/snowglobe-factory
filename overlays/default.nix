{ flake }:
let
  inputs = flake.inputs;
in
rec {
  snowglobe-pkgs =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
    in
    # custom packages
    import ../packages {
      pkgs = final;
      inherit flake;
    }
    # extra vim plugins not in nixpkgs
    // {
      vimPlugins =
        prev.vimPlugins
        // import ../packages/vimPlugins {
          pkgs = final;
        };
    }
    # patches for things that dont build or aren't packaged correctly
    // import ./package-patches {
      inherit final prev;
      nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
    }
    # packages from other flakes that either dont provide overlays, or I just want a subset for them.
    // {
      distro-grub-themes = inputs.distro-grub-themes.packages.${system};
    };

  # overlays from other flakes. These are auto consumed with the modulesets.
  nix-post-build-hook-queue = inputs.nix-post-build-hook-queue.overlays.default;
  flux = inputs.flux.overlays.default;

  default = snowglobe-pkgs;
}
