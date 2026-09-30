{
  disabledModules = [
    # so poorly written and annoying to work with that dozens of projects have tried to replace it
    "programs/neovim.nix"
    # forces a service unit and is not very flexible
    "programs/wayland/waybar.nix"
  ];
}
