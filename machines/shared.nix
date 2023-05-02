{ lib, pkgs, inputs, ... }:
{
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
    killall
    niv
  ];

  programs.fish.enable = true;
}
