{
  flake,

  lib,
  writeShellApplication,
  gitMinimal,
  fzf,
  nvd,
  nix-output-monitor,
}:
writeShellApplication {
  name = "snowglobe-rebuild";
  bashOptions = [ ];
  checkPhase = "";
  text = lib.replaceString "#!/bin/sh" "" (
    builtins.readFile (flake + "/lib/scripts/snowglobe-rebuild.sh")
  );
  runtimeInputs = [
    gitMinimal
    fzf
    nix-output-monitor
    nvd
  ];
}
