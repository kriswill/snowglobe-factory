{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "kiwix-desktop";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "a program to download information for offline use";
    programName = programName;
    packageName = "kiwix";
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
    }
  );
}
