{ config, lib, pkgs, ... }:
let
  libx = import ./lib.nix { inherit lib; };
  inherit (libx) mkBinds;
  mkContainer = libx.mkContainer {
    ephemeral = true;
    autoStart = true;
    enableTun = true;
    privateNetwork = true;
    hostBridge = "br0";

    config = { config, ... }: {
      nixpkgs.pkgs = pkgs;
      networking.interfaces.eth0.useDHCP = true;
      services.tailscale.enable = true;
      networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      system.stateVersion = "23.05";
    };
  };
in
{
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "nixsrv";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "br0" "tailscale0" ];
  };

  networking.interfaces.ens18.useDHCP = true;

  networking.bridges.br0 = { interfaces = [ ]; };
  networking.interfaces.br0.ipv4.addresses = [{ address = "172.16.0.1"; prefixLength = 24; }];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "ens18";
    extraCommands = ''
      iptables -A FORWARD -i br0 -m state --state RELATED,ESTABLISHED -j ACCEPT

      iptables -A FORWARD -i br0 -d 10.0.0.0/8 -j DROP
      iptables -A FORWARD -i br0 -d 172.16.0.0/12 -j DROP
      iptables -A FORWARD -i br0 -d 192.168.0.0/16 -j DROP
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
  services.tailscale.openFirewall = true;

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

    "d /pool/container-data/ombi/config 0755 root root -"
    "d /pool/container-data/ombi/tailscale 0755 root root -"

    "d /pool/container-data/vaultwarden/data 0755 root root -"
    "d /pool/container-data/vaultwarden/tailscale 0755 root root -"

    "d /pool/container-data/whoogle/config 0755 root root -"
    "d /pool/container-data/whoogle/tailscale 0755 root root -"
  ];

  containers.sabnzbd = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/sabnzbd:/pool/container-data/sabnzbd/config"
      "/var/lib/tailscale:/pool/container-data/sabnzbd/tailscale"
      "/downloads:/pool/downloads"
    ];
    config = _: {
      services.sabnzbd.enable = true;
      services.sabnzbd.package = pkgs.unstable.sabnzbd;
      systemd.tmpfiles.rules = [
        "d /var/lib/sabnzbd 0755 sabnzbd sabnzbd -"
      ];
    };
  };

  containers.sonarr = mkContainer {
    bindMounts = mkBinds [
      "/config:/pool/container-data/sonarr/config"
      "/var/lib/tailscale:/pool/container-data/sonarr/tailscale"
      "/downloads:/pool/downloads"
      "/tv:/pool/media/tv"
    ];
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
    bindMounts = mkBinds [
      "/config:/pool/container-data/radarr/config"
      "/var/lib/tailscale:/pool/container-data/radarr/tailscale"
      "/downloads:/pool/downloads"
      "/movies:/pool/media/movies"
    ];
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
    bindMounts = mkBinds [
      "/var/lib/plex:/pool/container-data/plex/data"
      "/var/lib/tailscale:/pool/container-data/plex/tailscale"
      "/media:/pool/media"
    ];
    config = _: {
      services.plex.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/plex 0755 plex plex -"
      ];
    };
  };

  containers.ombi = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/ombi:/pool/container-data/ombi/config"
      "/var/lib/tailscale:/pool/container-data/ombi/tailscale"
    ];
    config = _: {
      services.ombi.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/ombi 0755 ombi ombi -"
      ];
    };
  };

  containers.whoogle = mkContainer {
    bindMounts = mkBinds [
      "/var/lib/tailscale:/pool/container-data/whoogle/tailscale"
    ];
    extraFlags = [
      "--system-call-filter=keyctl"
      "--system-call-filter=bpf"
    ];
    additionalCapabilities = [ "all" ];
    config = _: {
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers = {
        whoogle = {
          image = "benbusby/whoogle-search";
          autoStart = true;
          ports = [ "127.0.0.1:5000:5000" ];
          environment = import ./whoogle-env.nix;
        };
      };
    };
  };
}
