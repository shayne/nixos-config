{ config, pkgs, lib, inputs, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.sessionVariables.NIXNAME = "wsl2-amd64";

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "shayne";
    wslConf.network.hostname = "wsl";
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

  hardware.opengl.enable = true;

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

  virtualisation.docker.enable = true;

  # nixpkgs.overlays = [
  #   (self: super: {
  #     docker = super.docker.override { iptables = pkgs.iptables-legacy; };
  #   })
  # ];

  environment.etc."resolv.conf".text = ''
    nameserver 10.2.2.10
    search lan
  '';
}
