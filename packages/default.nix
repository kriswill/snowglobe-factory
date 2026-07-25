{ pkgs, flake }:
let
  inherit (pkgs) callPackage;
in
{
  snowglobe-rebuild = callPackage ./snowglobe-rebuild/package.nix { inherit flake; };
  snowglobe-install = callPackage ./snowglobe-install/package.nix { inherit flake; };
  omori-font = callPackage ./omori-font/package.nix { };
  _8bit-operator-font = callPackage ./_8bit-operator-font/package.nix { };
  star-pixel-icons = callPackage ./star-pixel-icons/package.nix { };
  helium = callPackage ./helium/package.nix { };
}
