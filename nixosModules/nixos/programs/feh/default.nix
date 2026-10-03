{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "feh";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "an image viewer for x11 that can also set backgrounds.";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
    }
  );
}
