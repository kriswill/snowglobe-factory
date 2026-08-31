{
  flake,

  writeShellApplication,
  gitMinimal,
  fzf,
  nvd,
}:
writeShellApplication {
  name = "snowglobe-rebuild";
  bashOptions = [ ];
  checkPhase = "";
  text = builtins.readFile (flake + "/lib/scripts/snowglobe-rebuild.sh");
  runtimeInputs = [
    gitMinimal
    fzf
    nvd
  ];
}
