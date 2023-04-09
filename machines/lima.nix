{ config, modulesPath, pkgs, lib, ... }:
{
  imports = [
    ./lima/init.nix
  ];

  networking.hostName = "lima";
  networking.firewall.enable = false;

  # Set your time zone.
  time.timeZone = "America/New_York";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub.configurationLimit = 2;

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.users.root.password = "nixos";

  security = {
    sudo.wheelNeedsPassword = false;
  };

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    wget
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "22.11";
}
