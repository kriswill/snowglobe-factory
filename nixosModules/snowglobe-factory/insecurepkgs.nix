# list of insecure nixpkgs.
# TODO check on this file and remove any unneeded permissions for the current flake revision.
{
  nixpkgs.config.permittedInsecurePackages = [
    # decky-loader from jovian-nixos requires this
    "pnpm-9.15.9"
    # vesktop requires this
    "electron-40.10.5"
  ];
}
