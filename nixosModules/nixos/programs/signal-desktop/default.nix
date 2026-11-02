{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "signal-desktop";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "a desktop version of the signal mobile app";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
    }
  );
}
