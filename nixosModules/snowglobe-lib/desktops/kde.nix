{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-lib.desktop.kde;
in
{
  options.snowglobe-lib.desktop.kde.enable = lib.mkEnableOption "Snowglobe-Lib's KDE plasma module";

  config = lib.mkIf cfg.enable {
    # ensure KDE cannot be enabled with DIY desktops, too many things will break due to KDE's invasiveness
    assertions =
      lib.mkIf
        (
          config.snowglobe-lib.desktop.niri.enable
          || config.snowglobe-lib.desktop.hyprland.enable
          || config.snowglobe-lib.desktop.labwc.enable
        )
        [
          {
            assertion = false;
            message = "You cannot use other snowglobe-lib.desktop modules in conjuction with KDE.";
          }
        ];

    snowglobe-lib = {
      system.hasDesktop = lib.mkForce true;
      desktop = {
        enable = true;
      };
    };

    # small debloat effort
    environment = {
      plasma6.excludePackages = builtins.attrValues {
        inherit (pkgs.kdePackages)
          khelpcenter
          kinfocenter
          ;
      };
    };

    # script which will repair imperative icons pinned to taskbar and desktop by users
    system.userActivationScripts = {
      fix-plasma-icons.text = ''
        # script that will repair KDE plasma icons after a flake update.
        # Instead of referencing icons at the correct location /run/current-system/sw/share/applications, Freaking kde plasma just references the /nix/store directly for some reason.
        # On NixOS (if you do not use home-manager) you should NEVER have files in your home directory that reference the /nix/store directly ever.
        # Every time the NAR hashes of the store update, the imperatively created links will not update by default.
        # This causes the icons on KDE plasma to disappear because they now reference a store path that doesn't exist.

        # fix icons on the taskbar
        ${pkgs.gnused}/bin/sed -i 's/\/nix\/store\/[A-Za-z0-9]\+-system-path\/share\/applications/\/run\/current-system\/sw\/share\/applications/g' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

        # Fix symlinks in /home/user/Desktop
        DESKTOP_DIR="$HOME/Desktop"
        for file in "$DESKTOP_DIR"/*; do
          FILE_NAME=$(printf "$file" | rev | cut -d/ -f1 | rev)
          case "$(readlink "$file")" in
            "/nix/store"*)
              rm "$file"
              ln -s "/run/current-system/sw/share/applications/$FILE_NAME" "$file"
              ;;
            *)
              continue
              ;;
            esac
          done
      '';
    };

    # make sure plasma can manage the QT configuration independent of nix by default
    qt.platformTheme = lib.mkOverride 899 null;
    qt.style = lib.mkOverride 899 null;

    # disable other polkit-agents in favor of kde polkit agent
    security.soteria.enable = false;
    services.polkit-gnome.enable = false;

    services = {
      desktopManager.plasma6 = {
        enable = true;
      };

      # use builtin plasma bluetooth
      blueman.enable = slib.overrideDefault false;

      # use sddm as display manager
      displayManager.ly.enable = false;
      displayManager.sddm.enable = true;

      gnome = {
        gnome-software.enable = slib.overrideDefault false;
        gnome-keyring.enable = slib.overrideDefault false;
      };
    };

    programs = {
      # disable pwvucontrol in favor of the default plasma volume control
      pwvucontrol.enable = slib.overrideDefault false;
      # disable swaync for plasma's notification daemon
      swaync.enable = slib.overrideDefault false;
      # disable batsignal
      batsignal.enable = slib.overrideDefault false;
      # kde has its own notepad
      mousepad.enable = slib.overrideDefault false;
      # disable gnome-disks in favor of kde-partition-manager
      gnome-disks.enable = slib.overrideDefault false;
      partition-manager.enable = slib.setDefault true;
      # use dolphin instead of nautilus
      nautilus.enable = slib.overrideDefault false;
      # prevent 2 network manager applets
      networkmanagerapplet.enable = slib.overrideDefault false;
      # disable nwg-look
      nwg-look.enable = slib.overrideDefault false;
      # disable selectdefault application
      selectdefaultapplication.enable = slib.overrideDefault false;
    };
  };
}
