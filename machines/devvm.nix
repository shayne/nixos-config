{ config, pkgs, ... }:

{
  imports = [
    ../secret/modules/cron.nix
    ../secret/modules/caddy.nix
  ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking.useDHCP = false;

  networking.hostName = "devvm";

  networking.interfaces.ens18.useDHCP = true;

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
    tailscale
  ];

  programs.mosh.enable = true;

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  services.code-server = {
    enable = true;
    user = "shayne";
    group = "users";
    port = 3000;
    auth = "none";
  };

  networking.firewall.enable = false;

  system.stateVersion = "20.09";
}
