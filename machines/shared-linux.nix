{ lib, pkgs, inputs, ... }:
{
  imports =[
    inputs.vscode-server.nixosModule
  ];

  nix.gc = {
    automatic = true;
    dates = "03:15";
    options = "-d";
  };

  environment.systemPackages = with pkgs; [
    iptables
  ];

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";

  security.sudo.wheelNeedsPassword = false;

  services.vscode-server.enable = true;
} 
