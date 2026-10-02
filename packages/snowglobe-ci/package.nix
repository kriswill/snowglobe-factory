{
  flake,

  stdenvNoCC,
  lib,
  writeShellApplication,
  git,
  libnotify,
  fzf,
  openssh,
  gnupg,
  netcat,
  nix-output-monitor,
  iputils,
  systemd,
}:
writeShellApplication {
  name = "ci.sh";
  bashOptions = [ ];
  checkPhase = "";
  text = lib.replaceString "#!/bin/sh" "" (
    builtins.readFile (flake + "/lib/scripts/snowglobe-ci.sh")
  );
  runtimeInputs = [
    git
    fzf
    openssh
    gnupg
    libnotify
    netcat
    nix-output-monitor
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
    iputils
    systemd
  ];
}
