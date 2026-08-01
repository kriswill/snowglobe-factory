{
  flake,

  writeShellApplication,
  gitMinimal,
  fzf,
  nvd,
}:
let
in
writeShellApplication {
  name = "snowglobe-rebuild";
  bashOptions = [ ];
  text = builtins.readFile (flake + "/lib/scripts/snowglobe-rebuild.sh");
  runtimeInputs = [
    gitMinimal
    fzf
    nvd
  ];
}
