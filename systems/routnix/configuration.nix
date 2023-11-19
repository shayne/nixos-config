{ config, lib, pkgs, ... }:
{
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "routnix";

  networking.interfaces.eth0.useDHCP = true;

  services.tailscale.enable = true;
}
