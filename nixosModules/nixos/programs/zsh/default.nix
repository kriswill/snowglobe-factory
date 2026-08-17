{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "zsh";
  cfg = config.programs.${programName};
in
{
  options.programs.zsh = slib.mkProgramOption {
    inherit programName pkgs;
    excludedOptions = [
      "enable"
      # TODO after flake update
      # "package"
    ];
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        environment.systemPackages =
          [ ]
          ++ lib.optionals (cfg.syntaxHighlighting.enable) [
            pkgs.zsh-syntax-highlighting
          ]
          ++ lib.optionals (cfg.autosuggestions.enable) [
            pkgs.zsh-autosuggestions
          ];
      };
    }
  );
}
