{
  flake,

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
  text = builtins.readFile (flake + "/lib/scripts/snowglobe-rebuild.sh");
  runtimeInputs = [
    gitMinimal
    fzf
    nix-output-monitor
    nvd
  ];
}
