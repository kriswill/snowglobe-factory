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
  text = builtins.readFile (flake + "/lib/scripts/snowglobe-rebuild.sh");
  runtimeInputs = [
    gitMinimal
    fzf
    nvd
  ];
}
