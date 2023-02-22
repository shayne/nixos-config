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

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "ookla-speedtest"
  ];

  environment.systemPackages = with pkgs; [
    gnumake
    iptables
    killall
    niv
  ];

  programs.fish.enable = true;

  services.vscode-server.enable = true;
}
