{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/mnt/macos" = {
    device = "share";
    fsType = "virtiofs";
  };

  fileSystems."/home/shayne/code" = {
    device = "/mnt/macos/code";
    fsType = "fuse.bindfs";
    options = [
      "map=0/1000:@0/@100"
      "x-systemd.requires=/mnt/macos"
    ];
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];
}
