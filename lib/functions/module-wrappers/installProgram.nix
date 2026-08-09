# function to install custom program options created by mkProgramOption globally or for specified users
{ lib }:
{
  programName,
  config,
  extraModules ? { },
}:
let
  programcfg = config.programs.${programName};
  programPackage = programcfg.package;
in
lib.mkMerge [
  (lib.mkIf programcfg.installGlobally ({
    environment.systemPackages = [ programPackage ];
  }))

  (lib.mkIf (programcfg.installForUsers != [ ]) {
    programs.${programName} = {
      userPackages = (
        lib.genAttrs programcfg.installForUsers (username: lib.mkOverride 1350 programPackage)
      );
    };
  })
  {
    users.users = lib.mkIf (programcfg.userPackages != { }) (
      lib.genAttrs (lib.attrNames programcfg.userPackages) (
        username:
        let
          userPackage = programcfg.userPackages.${username};
        in
        {
          packages = [ userPackage ];
        }
      )
    );
  }

  extraModules

  {
    # sanity checks
    assertions = [
      {
        assertion = (programcfg.installGlobally || programcfg.installForUsers != [ ]);
        message = ''
          programs.${programName} is enabled but neither has installGlobally nor installForUsers set. 
          You must set one of the options.
        '';
      }
    ];
  }
]
