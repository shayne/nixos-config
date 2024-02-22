{ config, pkgs, ... }:

{
  imports = [
  ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=false" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking.useDHCP = false;

  networking.hostName = "m3vm";

  networking.interfaces.enp0s1.useDHCP = true;

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

  # nixpkgs.config.permittedInsecurePackages = [
  #   "nodejs-16.20.1"
  # ];
  # services.code-server = {
  #   enable = false;
  #   user = "shayne";
  #   group = "users";
  #   port = 3000;
  #   auth = "none";
  # };

#   services.openvscode-server = {
#     enable = true;
#     user = "shayne";
#     group = "users";
#     host = "0.0.0.0";
#     port = 3000;
#     withoutConnectionToken = true;
#   };

  networking.firewall.enable = false;
}
