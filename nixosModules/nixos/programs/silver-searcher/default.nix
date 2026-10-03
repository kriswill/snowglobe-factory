{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "silver-searcher";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "a code-searching tool similar to ack, but faster";
    programName = programName;
    packageName = "silver-searcher-ng"; # revived version of the repo
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
    }
  );
}
