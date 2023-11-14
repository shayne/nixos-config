{ config, lib, pkgs, ... }:
let
  mkContainer = cattrs: recursiveMergeAttrs [
    {
      ephemeral = true;
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostBridge = "br0";
    }
    cattrs
    {
      config = args: recursiveMergeAttrs [
        (cattrs.config args)
        {
          nixpkgs.pkgs = pkgs;
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
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "nixsrv";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "br0" ];
  };

  networking.interfaces.ens18.useDHCP = true;
  networking.interfaces.ens19.useDHCP = false;

  networking.bridges.br0 = { interfaces = [ ]; };
  networking.interfaces.br0.ipv4.addresses = [{ address = "172.16.0.1"; prefixLength = 24; }];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "ens18";
    extraCommands = ''
      iptables -A FORWARD -i br0 -s 172.16.0.0/24 -d 10.0.0.0/8 -j DROP
      iptables -A FORWARD -i br0 -s 172.16.0.0/24 -d 172.16.0.0/12 -j DROP
      iptables -A FORWARD -i br0 -s 172.16.0.0/24 -d 192.168.0.0/16 -j DROP
    '';
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      dhcp-range = "172.16.0.2,172.16.0.254,24h";
      listen-address = "172.16.0.1";
    };
  };

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /pool/downloads/complete 0777 root root -"
    "d /pool/downloads/incomplete 0777 root root -"

    "d /pool/media/tv 0777 root root -"
    "d /pool/media/movies 0777 root root -"

    "d /pool/container-data/sabnzbd/config 0755 root root -"
    "d /pool/container-data/sabnzbd/tailscale 0755 root root -"

    "d /pool/container-data/sonarr/config 0755 root root -"
    "d /pool/container-data/sonarr/tailscale 0755 root root -"

    "d /pool/container-data/radarr/config 0755 root root -"
    "d /pool/container-data/radarr/tailscale 0755 root root -"

    "d /pool/container-data/plex/data 0755 root root -"
    "d /pool/container-data/plex/tailscale 0755 root root -"
  ];

  containers.sabnzbd = mkContainer {
    bindMounts = {
      "/var/lib/sabnzbd" = {
        hostPath = "/pool/container-data/sabnzbd/config";
        isReadOnly = false;
      };
      "/var/lib/tailscale" = {
        hostPath = "/pool/container-data/sabnzbd/tailscale";
        isReadOnly = false;
      };
      "/downloads" = {
        hostPath = "/pool/downloads";
        isReadOnly = false;
      };
    };
    config = _: {
      services.sabnzbd.enable = true;
      services.sabnzbd.package = pkgs.unstable.sabnzbd;
      systemd.tmpfiles.rules = [
        "d /var/lib/sabnzbd 0755 sabnzbd sabnzbd -"
      ];
    };
  };

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
      "/downloads" = {
        hostPath = "/pool/downloads";
        isReadOnly = false;
      };
      "/tv" = {
        hostPath = "/pool/media/tv";
        isReadOnly = false;
      };
    };
    config = _: {
      services.sonarr.enable = true;
      services.sonarr.package = pkgs.unstable.sonarr;
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
      "/downloads" = {
        hostPath = "/pool/downloads";
        isReadOnly = false;
      };
      "/movies" = {
        hostPath = "/pool/media/movies";
        isReadOnly = false;
      };
    };
    config = _: {
      services.radarr.enable = true;
      services.radarr.dataDir = "/config";
      services.radarr.package = pkgs.unstable.radarr;
      systemd.tmpfiles.rules = [
        "d /config 0755 radarr radarr -"
      ];
    };
  };

  containers.plex = mkContainer {
    bindMounts = {
      "/var/lib/plex" = {
        hostPath = "/pool/container-data/plex/data";
        isReadOnly = false;
      };
      "/var/lib/tailscale" = {
        hostPath = "/pool/container-data/plex/tailscale";
        isReadOnly = false;
      };
      "/media" = {
        hostPath = "/pool/media";
        isReadOnly = false;
      };
    };
    config = _: {
      services.plex.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/plex 0755 plex plex -"
      ];
    };
  };
}
