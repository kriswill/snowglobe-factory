{
  flake,

  lib,
  writeShellApplication,
  gitMinimal,
  bat,
  gnused,
  disko,
  sops,
  age,
  openssh,
  fzf,
}:
writeShellApplication {
  name = "install.sh";
  bashOptions = [ ];
  checkPhase = "";
  text = lib.replaceString "#!/bin/sh" "" (
    builtins.readFile (flake + "/lib/scripts/snowglobe-install.sh")
  );
  runtimeInputs = [
    gitMinimal
    fzf
    bat
    openssh
    disko
    sops
    age
    gnused
  ];
}
