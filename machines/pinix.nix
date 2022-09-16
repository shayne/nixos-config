
{ config, pkgs, lib, user, ... }:

{
  imports = [
    "${fetchTarball { url = "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz"; sha256 = "sha256:06g0061xm48i5w7gz5sm5x5ps6cnipqv1m483f8i9mmhlz77hvlw"; }}/raspberry-pi/4"];

  networking = {
    hostName = "pinix";
    interfaces.eth0.useDHCP = true;
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