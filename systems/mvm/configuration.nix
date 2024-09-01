{ pkgs, ... }:
{
  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking.useDHCP = false;
  networking.hostName = "mvm";
  networking.firewall.enable = false;
  networking.interfaces.enp0s1.useDHCP = true;

  # Virtualization settings
  virtualisation.docker.enable = true;
  virtualisation.rosetta.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [
    bindfs
    gnumake
    killall
    niv
    tailscale
    iptables
  ];

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;
}
