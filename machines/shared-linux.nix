{ lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.vscode-server.nixosModule
  ];

  environment.systemPackages = with pkgs; [
    iptables
  ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  security.sudo.wheelNeedsPassword = false;

  services.vscode-server.enable = true;
}
