{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "zapp";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "terminal based flash utility for ZSA keyboards";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        hardware.keyboard.zsa.enable = true;
      };
    }
  );
}
