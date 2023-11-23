{ myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/acme")
  ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "routnix";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  networking.interfaces.eth0.useDHCP = true;

  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  services.nginx.enable = true;
  services.nginx.virtualHosts =
    let
      base = locations: {
        inherit locations;

        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
      };
    in
    {
      "default.foo.ss.ht" = base
        {
          "/" = {
            extraConfig = ''
              return 200 "";
              add_header Content-Type text/plain;
            '';
          };
        } // { default = true; };
    } // import ./virtual-hosts.enc.nix base;
}
