{ config, pkgs, ... }:

{
  imports = [
    ../secret/modules/cron.nix
    ../secret/modules/caddy.nix
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    ''; # for direnv
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking.useDHCP = false;

  networking.hostName = "devvm";

  networking.interfaces.enp1s0.useDHCP = true;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

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

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
  ];

  programs.mosh.enable = true;

  services.qemuGuest.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;
  services.openssh.permitRootLogin = "no";

  networking.firewall.enable = false;

  system.stateVersion = "20.09";
}
