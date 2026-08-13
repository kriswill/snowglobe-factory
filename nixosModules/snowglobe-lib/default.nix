{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.enable = lib.mkEnableOption "Snowglobe-Lib's default NixOS configuration";

  config = lib.mkIf config.snowglobe-lib.enable {
    # custom patches and configs
    # -----------------------------
    snowglobe-lib =
      let
        hasDesktop = (config.snowglobe-lib.system.hasDesktop);
        gpu-vendors = config.snowglobe-lib.system.gpu-vendors;
        hasElem = builtins.elem;
      in
      {
        # enable gpu configurations
        gpu = {
          amd.enable = hasElem "amd" gpu-vendors;
          intel.enable = hasElem "intel" gpu-vendors;
          nvidia.enable = hasElem "nvidia" gpu-vendors;
        };

        boot-config.enable = slib.setDefault true;
        # module to strip out some fluff that headless linux systems dont need.
        headless-debloater.enable = slib.setDefault (!hasDesktop);
        # use the timezone detector based on IP geolocation if a static timezone is not set
        # Note: using a vpn can cause this module to give the incorrect timezone
        timezone-detector.enable = slib.setDefault (config.time.timeZone == null);
      };

    # core nixos modules
    # ------------------

    # extra caches
    # use of custom substitutor module. see nixosModules/nixos/substituters.nix;
    substituters = {
      # Warning: Personal server for ensuring package patches in overlays/package-patches get cached.
      # Users have the option to enable or disable this per-host depending on the installer type used.
      "nix-store.earthgman.dev" = {
        enable = slib.setDefault true;
        publicKey = "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw=";
        # set lower priority than cache.nixos.org by default
        priority = slib.setDefault 100;
      };
    };

    nix = {
      settings = {
        # allow fallbacks if a substituter is down
        fallback = slib.setDefault true;
        # enable flakes
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # enable hard linking of identical contents within the nix store
        auto-optimise-store = slib.setDefault true;
      };
    };

    nixpkgs = {
      config = {
        # lift restrictions for unfree software
        # you dont have to install it, but give users the ability to without hassle
        allowUnfree = slib.setDefault true;
      };
    };

    # remove nixos documentation
    documentation.nixos.enable = slib.setDefault false;

    # enable the linux-firmware repository if not in a virtual machine
    hardware.enableRedistributableFirmware = slib.setDefault (!config.snowglobe-lib.system.isVM);

    networking = {
      # use networkmanager for connections
      networkmanager.enable = slib.setDefault true;
      # use nftables over iptables
      nftables.enable = slib.setDefault true;
      # dont allow ICMP pings by default
      firewall.allowPing = slib.setDefault false;
    };

    boot = {
      # everyone gets the latest kernel
      kernelPackages = slib.setDefault pkgs.linuxPackages_latest;
      # clean garbage from tmp
      tmp.cleanOnBoot = slib.setDefault true;

      loader = {
        # allow the installer to change boot order / other important variables for UEFI systems
        efi.canTouchEfiVariables = slib.setDefault true;
      };
    };

    # setup sops configuration
    sops = {
      defaultSopsFormat = slib.setDefault "yaml";
      # set to roots config so new installs can edit secrets as the super user
      age.keyFile = slib.setDefault "/root/.config/sops/age/keys.txt";
    };

    # link /root/.ssh keyfiles to /etc/ssh
    systemd.tmpfiles.rules = [
      "L /root/.ssh/id_ed25519 - - - - /etc/ssh/ssh_host_ed25519_key"
      "L /root/.ssh/id_ed25519.pub - - - - /etc/ssh/ssh_host_ed25519_key.pub"
      "L /root/.ssh/id_rsa - - - - /etc/ssh/ssh_host_rsa_key"
      "L /root/.ssh/id_rsa.pub - - - - /etc/ssh/ssh_host_rsa_key.pub"
    ];

    environment = {
      # use dash as /bin/sh of choice
      # override weights are hardcoded into nixpkgs using lib.mkDefault
      binsh = slib.overrideNixpkgsDefault "${pkgs.dash}/bin/dash";

      # these are not set properly on nixos by default for some reason
      # TODO check on status of this: https://github.com/NixOS/nixpkgs/issues/286283
      sessionVariables = {
        SYSTEMD_KEYMAP_DIRECTORIES = slib.setDefault "${pkgs.kbd}/share/keymaps";
      };

      systemPackages = with pkgs; [
        # install sops cli tools
        sops
        age

        # make sure terminfo for popular terminals is installed for smooth ssh connections
        # TODO add more if needed
        kitty.terminfo
        alacritty.terminfo
        foot.terminfo
        ghostty.terminfo
        wezterm.terminfo
        st.terminfo
      ];
    };

    # give people zsh by default since most enthusists just replace bash with it anyway
    # comes with syntaxhighlighting and autosuggesions enabled
    users.defaultUserShell = slib.overrideNixpkgsDefault config.programs.zsh.package;

    # make sure that the virtual consoles (TTY) respect the xserver keyboard keymap chosen in the installer
    console.useXkbConfig = slib.setDefault true;

    # enable tools / software and their configurations
    programs = {
      # use neovim and alias vim to it by default
      vim.enable = slib.setDefault false;
      # cat with colorized output
      bat.enable = slib.setDefault true;
      # brightness control
      brightnessctl.enable = slib.setDefault true;
      # many useful unix utilities
      busybox.enable = slib.setDefault true;
      # drop-in nix replacement with a fancy screen
      nix-output-monitor.enable = slib.setDefault true;
      # easily search through nixpkgs and try out software without actually installing it persistently
      # use , programname
      nix-index-database = {
        enable = slib.setDefault true;
        comma.enable = slib.setDefault true;
      };
      # nix version diff
      nvd.enable = slib.setDefault true;
      # wrapper around several nixos tools like nom and nvd
      nh = {
        enable = slib.setDefault true;
        flake = slib.setDefault "/etc/nixos";
        # by default clean contents of the nix-store not related to this machine's nixos config every so often.
        clean = {
          enable = slib.setDefault true;
        };
      };
      # make obs more beginner friendly
      obs-studio.enableVirtualCamera = slib.setDefault true;
      # declarative disk partitioning tool
      disko.enable = slib.setDefault true;
      # vencord
      discord.package = slib.setDefault pkgs.vesktop;
      # hardened firefox
      firefox.package = slib.setDefault pkgs.librewolf;
      # bloat finder
      ncdu.enable = slib.setDefault true;
      # terminal multiplexer
      tmux.enable = slib.setDefault true;
      # make sure libreoffice is bleeding edge
      libreoffice.package = slib.setDefault pkgs.libreoffice-fresh;
      # alias to neovim if enabled
      neovim = {
        enable = slib.setDefault true;
        viAlias = slib.setDefault true;
        vimAlias = slib.setDefault (!config.programs.vim.enable);
      };
      # give otp support for 2fa with pass
      password-store.package = slib.setDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));
      # system information
      fastfetch.enable = slib.setDefault true;
      # file info fetcher
      file.enable = slib.setDefault true;
      # very good picker tool for CLI
      fzf.enable = slib.setDefault true;
      # make ls output prettier
      eza.enable = slib.setDefault true;
      # json query tool
      jq.enable = slib.setDefault true;
      # better top
      btop.enable = slib.setDefault true;
      # fuzzy finder and manager for systemd units
      sysz.enable = slib.setDefault true;
      # wrapper script for nixos-rebuild
      snowglobe-rebuild.enable = slib.setDefault true;
      # open source version control system
      git.enable = slib.setDefault true;
      # TUI for managing git operations
      lazygit.enable = slib.setDefault config.programs.git.enable;
      # better grep
      ripgrep.enable = slib.setDefault true;
      # tui file manager
      yazi.enable = slib.setDefault true;
      # cli archive maker
      zip.enable = slib.setDefault true;
      # that one shell that people always use
      zsh = {
        enable = slib.setDefault true;
        autosuggestions.enable = slib.setDefault true;
        syntaxHighlighting.enable = slib.setDefault true;
      };
    };

    services = {
      # run openssh by default
      openssh.enable = slib.setDefault true;
    };
  };
}
