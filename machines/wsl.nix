{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  networking.hostName = "wsl";
  networking.nameservers = [ "10.2.5.2" ];
  networking.search = [ "home.ss.ht" ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  wsl = {
    enable = true;
    defaultUser = "shayne";
    nativeSystemd = true;
    wslConf = {
      automount.root = "/mnt";
      network.hostname = "wsl";
      network.generateResolvConf = false;
    };
    # docker-desktop.enable = true;
    docker-native.enable = true;
    interop.register = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    wget
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # environment.etc."resolv.conf".enable = false;

  fonts = {
    fontDir.enable = true;

    fonts = [
      (builtins.path {
        name = "custom-fonts";
        path = ../secret/fonts;
        recursive = true;
      })
    ];
  };

  # nixpkgs.overlays = [
  #   (self: super: {
  #     docker = super.docker.override { iptables = pkgs.iptables-legacy; };
  #   })
  # ];

  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
  networking.firewall.checkReversePath = "loose";

  system.stateVersion = "22.05";
}
