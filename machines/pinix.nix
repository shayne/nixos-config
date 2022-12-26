
{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  networking = {
    hostName = "pinix";
    interfaces.eth0.useDHCP = true;
    firewall.enable = false;
    nameservers = [ "127.0.0.1" ];
  };

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv

    libraspberrypi
  ];

  virtualisation.docker.enable = true;

  services.openssh.enable = true;

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  # make vchiq owned by video
  services.udev.extraRules = ''
    SUBSYSTEM=="vchiq",GROUP="video",MODE="0660"
  '';
  # ...add user to video
  users.users.${user}.extraGroups = [ "video" ];

  system.stateVersion = "22.05";
}
