{
  flake,

  writeShellApplication,
  gitMinimal,
  bat,
  gnused,
  nixos-install-tools,
  nixos-install,
  disko,
  sops,
  age,
  openssh,
  fzf,
  nvd,
}:
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
    gnused
  ];
}
