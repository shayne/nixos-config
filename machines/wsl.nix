{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  networking.hostName = "wsl";

  wsl = {
    enable = true;
    defaultUser = "shayne";
    nativeSystemd = true;
    wslConf = {
      automount.root = "/mnt";
      network.hostname = "wsl";
    };
    # docker-desktop.enable = true;
    docker-native.enable = true;
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

  environment.etc."resolv.conf".text = ''
    nameserver 10.2.2.10
    search lan
  '';

  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose";

  services.vscode-server.installPath = "~/.vscode-server-insiders";

  system.stateVersion = "22.05";
}
