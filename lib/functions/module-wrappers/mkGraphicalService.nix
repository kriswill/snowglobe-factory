# return common configuration for a service that relies on
# a desktop environment and graphical-session.target
{ lib }:
{
  serviceName,
  package,
  binName ? serviceName, # name of executable
  programArgs ? [ ],
  waylandDependent ? false,
  extraServiceConfig ? { },
  extraUnitConfig ? { },
  extraDescription ? "",
  ...
}:
{
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    Type = lib.mkDefault "exec";
    ExecStart = lib.mkDefault (
      "${package}/bin/${binName}"
      + (lib.optionalString (programArgs != [ ]) " " + (lib.concatStringsSep " " programArgs))
    );
    Restart = lib.mkDefault "on-failure";
    RestartSec = lib.mkDefault 5;
    Slice = lib.mkDefault "app.slice";
  }
  // extraServiceConfig;

  unitConfig = {
    After = [ "graphical-session.target" ];
    ConditionEnvironment = lib.mkIf (waylandDependent) "WAYLAND_DISPLAY";
    # prevent infinite restarts
    StartLimitIntervalSec = 30;
    StartLimitBurst = 3;

    Description = serviceName + extraDescription;
    Requisite = [ "graphical-session.target" ];
    PartOf = [ "graphical-session.target" ];
  }
  // extraUnitConfig;
}
