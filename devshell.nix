{ flake, pkgs }:
let
  system = pkgs.stdenvNoCC.hostPlatform.system;
  formatter = flake.outputs.formatter.${system};
in
{

  default = pkgs.mkShell {
    shellHook = ''
      echo Activated devshell
      echo You can now run ci.sh
      export SNOWGLOBE_DEVSHELL=1
    '';

    packages = [
      formatter
    ]
    ++ (with pkgs; [
      snowglobe-rebuild
      snowglobe-install
      snowglobe-ci
    ]);
  };
}
