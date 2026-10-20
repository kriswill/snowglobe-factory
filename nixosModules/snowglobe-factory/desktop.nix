{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-factory.desktop;
  cfgs = config.services;
  cfgp = config.programs;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
  isx86 = pkgs.stdenv.hostPlatform.isx86;
in
{
  options.snowglobe-factory.desktop = {
    enable = lib.mkEnableOption "snowglobe-factory's modules for systems with a desktop environment";
    installWaylandTools = lib.mkEnableOption "wayland tools for desktop.";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # x11 stack
      (lib.mkIf config.services.xserver.enable {
        programs = {
          xclip.enable = slib.setDefault true;
          xwallpaper.enable = slib.setDefault true;
          # screenshot tool
          maim.enable = slib.setDefault true;
        };
      })

      # wayland stack
      (lib.mkIf cfg.installWaylandTools {
        xdg.portal.wlr.enable = slib.setDefault true;

        programs = {
          # screenshot & clipboard tools
          grim.enable = slib.setDefault true;
          slurp.enable = slib.setDefault true;
          # clipboard
          wl-clipboard.enable = slib.setDefault true;
          # output control CLI for wlr-output-management
          wlr-randr.enable = slib.setDefault true;
          # graphical display control gui written in GTK
          wdisplays.enable = slib.setDefault true;
          # session and application manager for wayland under systemd
          # Some sessions (like niri) will not use this, but it doesn't hurt to install it anyway
          uwsm.enable = slib.setDefault true;
        };

        environment = {
          sessionVariables = {
            # force electron apps to run using wayland by default
            NIXOS_OZONE_WL = slib.setDefault "1";
          };
        };
      })
      # default configuration for all desktops
      {
        # populate system attribute
        snowglobe-factory.system.hasDesktop = lib.mkForce true;

        # fix blank screens in most java applications on some window managers.
        environment.sessionVariables._JAVA_AWT_WM_NONREPARENTING = slib.setDefault "1";
        # change the default display-manager from lightdm to ly. Runs on tty instead of x11 or wayland compositor.
        services.displayManager.ly.enable = slib.setDefault true;
        # enable polkit
        security.polkit = {
          enable = slib.setDefault true;
        };
        # add openvpn plugin to networkmanager
        networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

        # enable bluetooth if hardware is present
        hardware.bluetooth.enable = slib.setDefault true;
        # GTK gui for bluetooth
        services.blueman.enable = slib.setDefault config.hardware.bluetooth.enable;

        # use pulseaudio for the sound server by default
        # if using any wayland desktop this is replaced by pipewire
        security.rtkit.enable = slib.setDefault true; # hands out realtime scheduling priority to user processes on demand. Improves performance of pulse
        services.pulseaudio = {
          enable = slib.setDefault (!config.services.pipewire.enable);
          support32Bit = slib.setDefault isx86;
        };

        # prevent xterm from being installed by enabling the xserver
        services.xserver.excludePackages = [ pkgs.xterm ];

        # enable flatpak for ease of program installation and isolation for less savy users
        services.flatpak.enable = slib.setDefault true;

        services.gnome = {
          # flatpak frontend
          gnome-software.enable = slib.setDefault cfgs.flatpak.enable;
          # provide a default secret portal for independent window managers
          gnome-keyring.enable = slib.setDefault true;
        };

        programs = {
          # control applet for networkmanager
          nm-applet.enable = slib.setDefault true;
          # notification daemon api
          notify-send.enable = slib.setDefault true;
          # gtk and gnome software database
          dconf.enable = slib.setDefault true;
          # frontend to manage dconf
          dconf-editor.enable = slib.setDefault config.programs.dconf.enable;
          # media player
          vlc.enable = slib.setDefault true;
          # GTK management app for fonts icons cursors, etc for independent WMs
          pavucontrol.enable = slib.setDefault (
            config.services.pulseaudio.enable && (!config.services.pipewire.enable)
          );
          pwvucontrol =
            let
              ifPipewirePulse = (cfgs.pipewire.enable && cfgs.pipewire.pulse.enable);
            in
            {
              enable = slib.setDefault ifPipewirePulse;
              pavucontrolAlias = slib.setDefault ifPipewirePulse;
            };
          # calculator app
          gnome-calculator.enable = slib.setDefault true;
          # graphical udisks partition manager
          gnome-disks.enable = slib.setDefault true;
          # hardware info / device manager clone for linux
          hardinfo2.enable = slib.setDefault true;
          # secrets daemon frontend for gnome-keyring
          seahorse.enable = slib.setDefault config.services.gnome.gnome-keyring.enable;
          # xdg utilites for desktop shell scripting
          xdg-user-dirs.enable = slib.setDefault true;
          xdg-utils.enable = slib.setDefault true;
          # good tool that checks if a window is running in x11 or wayland
          xeyes.enable = slib.setDefault true;
        };

        # provide an icon theme
        environment.systemPackages = [ pkgs.adwaita-icon-theme ];

        fonts.packages = [
          # free fonts that support many locales
          pkgs.noto-fonts
          # ensure a nerd font is installed
          pkgs.nerd-fonts.meslo-lg
        ];

        # configures the xdg-desktop-portal, allowing standardized interprocess communication between applications
        # EX: opening a link from some app in the default browser
        xdg.portal = {
          enable = slib.setDefault true;
          # all xdg-open commands will use the portal configuration by default
          xdgOpenUsePortal = slib.setDefault true;
        };

        hardware.graphics = {
          enable = slib.setDefault true;
          # 32 bit support doesn't exist on other arches
          enable32Bit = lib.mkIf isx86 (slib.setDefault true);
        };
      }
    ]
  );
}
