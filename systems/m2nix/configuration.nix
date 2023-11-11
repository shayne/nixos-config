{ config, pkgs, lib, inputs, myModulesPath, ... }:

{
  imports = with inputs; [
    nixos-apple-silicon.nixosModules.apple-silicon-support
    (myModulesPath + "/hyprland")
  ];

  nixpkgs.config.allowUnsupportedSystem = true;

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;

  # Specify path to peripheral firmware files.
  hardware.asahi.peripheralFirmwareDirectory = ./firmware.enc;
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
    hostName = "m2nix"; # Define your hostname.
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
  programs.dconf.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    tailscale
    xclip
    libsForQt5.bismuth
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
}
