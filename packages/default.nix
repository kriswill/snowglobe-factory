{ pkgs, flake }:
let
  inherit (pkgs) callPackage;
in
{
  snowglobe-rebuild = callPackage ./snowglobe-rebuild/package.nix { inherit flake; };
  snowglobe-install = callPackage ./snowglobe-install/package.nix { inherit flake; };
  snowglobe-ci = callPackage ./snowglobe-ci/package.nix { inherit flake; };

  star-pixel-icons = callPackage ./star-pixel-icons/package.nix { };
  helium = callPackage ./helium/package.nix { };
}
// import ./vimPlugins { inherit pkgs; }
