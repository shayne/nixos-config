{ config, pkgs, ... }:

{
  imports = [
    ../../secret/modules/cron.nix
    ../../secret/modules/caddy.nix
  ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    tailscale
  ];

  programs.mosh.enable = true;

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.1"
  ];
  services.code-server = {
    enable = true;
    user = "shayne";
    group = "users";
    port = 3000;
    auth = "none";
  };

  networking.firewall.enable = false;
}
