{ config, lib, pkgs, ... }:
let
  mkContainer = cattrs: recursiveMergeAttrs [
    {
      ephemeral = true;
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostBridge = "br0";
      specialArgs = { inherit pkgs; };
    }
    cattrs
    {
      config = args: recursiveMergeAttrs [
        (cattrs.config args)
        {
          networking.interfaces.eth0.useDHCP = true;
          services.tailscale.enable = true;
          system.stateVersion = "23.05";
        }
      ];
    }
  ];
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
in
{
  time.timeZone = "America/New_York";

  networking.hostName = "nixsrv";
  networking.interfaces.ens18.useDHCP = true;
  networking.firewall.enable = false;

  networking.bridges = {
    # nixos container bridge
    br0 = { interfaces = [ "ens19" ]; };
  };

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    tailscale
  ];

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /pool/container-data/sonarr/config 0755 root root -"
    "d /pool/container-data/sonarr/tailscale 0755 root root -"
    "d /pool/container-data/radarr/config 0755 root root -"
    "d /pool/container-data/radarr/tailscale 0755 root root -"
  ];

  containers.sonarr = mkContainer {
    bindMounts = {
      "/config" = {
        hostPath = "/pool/container-data/sonarr/config";
        isReadOnly = false;
      };
      "/var/lib/tailscale" = {
        hostPath = "/pool/container-data/sonarr/tailscale";
        isReadOnly = false;
      };
    };
    config = _: {
      services.sonarr.enable = true;
      services.sonarr.dataDir = "/config";
      systemd.tmpfiles.rules = [
        "d /config 0755 sonarr sonarr -"
      ];
    };
  };

  containers.radarr = mkContainer {
    bindMounts = {
      "/config" = {
        hostPath = "/pool/container-data/radarr/config";
        isReadOnly = false;
      };
      "/var/lib/tailscale" = {
        hostPath = "/pool/container-data/radarr/tailscale";
        isReadOnly = false;
      };
    };
    config = _: {
      services.radarr.enable = true;
      services.radarr.dataDir = "/config";
      systemd.tmpfiles.rules = [
        "d /config 0755 radarr radarr -"
      ];
    };
  };
}
