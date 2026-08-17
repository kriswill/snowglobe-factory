{
  flake,

  writeShellApplication,
  gitMinimal,
  bat,
  nixos-install-tools,
  nixos-install,
  disko,
  sops,
  age,
  openssh,
  fzf,
  nvd,
}:
let
in
writeShellApplication {
  name = "install.sh";
  bashOptions = [ ];
  checkPhase = "";
  text = builtins.readFile (flake + "/lib/scripts/snowglobe-install.sh");
  runtimeInputs = [
    gitMinimal
    fzf
    bat
    nixos-install-tools
    nixos-install
    openssh
    disko
    sops
    age
  ];
}
