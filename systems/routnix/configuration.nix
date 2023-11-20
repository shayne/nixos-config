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
      proxy = domain: base {
        "/" = {
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Connection "";

            proxy_ssl_name ${domain};
            proxy_ssl_server_name on;
            proxy_ssl_session_reuse on;

            proxy_pass https://${domain};
            proxy_set_header X_FORWARDED_PROTO https;
          '';
        };
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
      # public services
      "o.foo.ss.ht" = proxy "ombi.shayne.ts.net";
    };
}
