{ config, lib, pkgs, ... }:
let
  libx = import ./lib.nix { inherit lib; };
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
    extraFlags = [
      "--bind /pool/container-data/sabnzbd/config:/var/lib/sabnzbd"
      "--bind /pool/container-data/sabnzbd/tailscale:/var/lib/tailscale"
      "--bind /pool/downloads:/downloads"
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
    extraFlags = [
      "--bind /pool/container-data/sonarr/config:/config"
      "--bind /pool/container-data/sonarr/tailscale:/var/lib/tailscale"
      "--bind /pool/downloads:/downloads"
      "--bind /pool/media/tv:/tv"
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
    extraFlags = [
      "--bind /pool/container-data/radarr/config:/config"
      "--bind /pool/container-data/radarr/tailscale:/var/lib/tailscale"
      "--bind /pool/downloads:/downloads"
      "--bind /pool/media/movies:/movies"
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
    extraFlags = [
      "--bind /pool/container-data/plex/data:/var/lib/plex"
      "--bind /pool/container-data/plex/tailscale:/var/lib/tailscale"
      "--bind /pool/media:/media"
    ];
    config = _: {
      services.plex.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/plex 0755 plex plex -"
      ];
    };
  };

  containers.ombi = mkContainer {
    extraFlags = [
      "--bind /pool/container-data/ombi/config:/var/lib/ombi"
      "--bind /pool/container-data/ombi/tailscale:/var/lib/tailscale"
    ];
    config = _: {
      services.ombi.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/ombi 0755 ombi ombi -"
      ];
    };
  };

  containers.whoogle = mkContainer {
    extraFlags = [
      "--bind /pool/container-data/whoogle/tailscale:/var/lib/tailscale"
      "--system-call-filter=keyctl"
      "--system-call-filter=bpf"
    ];
    additionalCapabilities = [ "all" ];
    config = _: {
      imports = [
        (import ./whoogle.enc.nix { inherit pkgs; })
      ];
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers = {
        whoogle = {
          image = "benbusby/whoogle-search";
          autoStart = true;
          ports = [ "127.0.0.1:5000:5000" ];
          extraOptions = [ "--dns=8.8.8.8" ];
          environment = { WHOOGLE_DOTENV = "1"; };
          environmentFiles = [ ./whoogle.enc.env ];
        };
      };
    };
  };
}
