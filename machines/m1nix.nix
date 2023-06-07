# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    ../secret/modules/wireguard.nix
  ];

  nixpkgs.config.allowUnsupportedSystem = true;

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;

  # Specify path to peripheral firmware files.
  hardware.asahi.peripheralFirmwareDirectory = ./apple-silicon-support/firmware;
  # Or disable extraction and management of them completely.
  # hardware.asahi.extractPeripheralFirmware = false;
  hardware.asahi.useExperimentalGPUDriver = true;

  # boot.kernelBuildIsCross = true;
  # don't build 16K just yet
  # boot.kernelBuildIs16K = false;

  boot.loader = {
    efi.canTouchEfiVariables = false;
    systemd-boot = {
      enable = true;
      # "error switching console mode" on boot.
      # no longer needed?
      # consoleMode = "auto";
      configurationLimit = 5;
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  networking = {
    hostName = "m1nix"; # Define your hostname.
    useDHCP = false;

    # Pick only one of the below networking options.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  services.blueman.enable = true;
  services.flatpak.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # setup windowing environment
  services.xserver = {
    enable = true;
    layout = "us";
    # dpi = 180;
    dpi = 150;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "scale";
    };

    libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
    };

    xkbOptions = "ctrl:nocaps";

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

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = [ # "eurosign:e"; "caps:escape" # map caps to escape.
  # ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.shayne = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

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
    gnumake
    killall
    niv
    tailscale
    xclip
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

  # enable the tailscale service
  services.tailscale.enable = true;
  systemd.services.tailscaled.wantedBy = lib.mkForce [ ];
  networking.firewall.checkReversePath = "loose";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.gvfs.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

