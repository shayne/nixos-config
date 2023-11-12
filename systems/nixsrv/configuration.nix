{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/New_York";

  networking.hostName = "nixsrv";
  networking.interfaces.ens18.useDHCP = true;
  networking.firewall.enable = false;

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    tailscale
  ];

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;
}
