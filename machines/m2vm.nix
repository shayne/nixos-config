{ config, pkgs, lib, currentSystem, currentSystemName,... }:

{
  imports = [
    ../modules/vmware-guest.nix
  ];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    systemd-boot = {
      enable = true;
      # VMware, Parallels both only support this being 0 otherwise you see
      # "error switching console mode" on boot.
      consoleMode = "auto";
      configurationLimit = 5;
    };
  };

  nix = {
    # mitchellh's public binary cache
    settings = {
      substituters = ["https://mitchellh-nixos-config.cachix.org"];
      trusted-public-keys = ["mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ="];
    };
  };

  # We expect to run the VM on hidpi machines.
  hardware.video.hidpi.enable = true;

  networking = {
    hostName = "m2vm";
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    # Disable the firewall since we're in a VM and we want to make it
    # easy to visit stuff in here. We only use NAT networking anyways.
    firewall.enable = false;
    # Interface is this on M2Air
    interfaces.ens160.useDHCP = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # setup windowing environment
  services.xserver = {
    enable = true;
    layout = "us";
    dpi = 220;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
    };

    displayManager = {
      defaultSession = "none+i3";
      lightdm = {
        enable = true;
        background = "#000000";
        autoLogin.timeout = 0;
      };

      autoLogin = {
        enable = true;
        user = "shayne";
      };

      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
      '';
    };

    windowManager = {
      i3.enable = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.
  fonts = {
    fontDir.enable = true;

    fonts = [
      pkgs.fira-code
      (builtins.path {
        name = "custom-fonts";
        path = ../secret/fonts;
        recursive = true;
      })
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    gtkmm3
    killall
    niv
    rxvt_unicode
    tailscale
    xclip

    # For hypervisors that support auto-resizing, this script forces it.
    # I've noticed not everyone listens to the udev events so this is a hack.
    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;
  services.openssh.permitRootLogin = "no";

  services.tailscale.enable = false;
  systemd.services.tailscaled.wantedBy = lib.mkForce [];

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
