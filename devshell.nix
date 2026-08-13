{ flake, pkgs }:
let
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  system = stdenv.hostPlatform.system;
  snowglobe-rebuild = flake.outputs.packages.${system}.snowglobe-rebuild;
  ci-sh = pkgs.runCommandLocal "snowglobe-lib-ci" { } ''
    mkdir -p $out/bin
    cp ${flake + "/lib/scripts/ci.sh"} $out/bin/ci.sh
  '';
  nix-formatter = flake.outputs.formatter.${system};
in
{

  default = pkgs.mkShell {
    shellHook = ''
      echo Activated devshell
      echo You can now run ci.sh
      export SNOWGLOBE_DEVSHELL=1
    '';

    packages = [
      ci-sh
      snowglobe-rebuild
      nix-formatter
      pkgs.openssh
      pkgs.gnupg
      pkgs.fzf
      pkgs.git
      pkgs.nix-output-monitor
      pkgs.libnotify
      pkgs.nvd
      pkgs.nh
      pkgs.netcat
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      pkgs.systemd
      pkgs.iputils
    ];
  };
}
