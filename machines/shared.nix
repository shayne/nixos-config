{ lib, pkgs, inputs, ... }:

{

  imports = [
    inputs.vscode-server.nixosModule
  ];

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  nix.gc = {
    automatic = true;
    dates = "03:15";
    options = "-d";
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "ookla-speedtest"
  ];

  environment.systemPackages = with pkgs; [
    gnumake
    iptables
    killall
    niv
  ];


  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";

  security.sudo.wheelNeedsPassword = false;

  programs.fish.enable = true;

  services.vscode-server.enable = true;

}
