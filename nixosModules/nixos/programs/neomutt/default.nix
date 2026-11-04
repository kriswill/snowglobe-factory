{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "neomutt";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "TUI email client";
    programName = programName;
    packageName = programName;
    inherit pkgs;
    extraOptions = {
      muttAlias = lib.mkOption {
        description = "whether to enable mutt -> neomutt alias";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        environment.systemPackages =
          let
            mutt-alias = slib.mkProgramAlias {
              program = "neomutt";
              alias = "mutt";
              package = cfg.package;
              inherit pkgs;
            };
          in
          lib.mkIf cfg.muttAlias [
            mutt-alias
          ];
      };
    }
  );
}
