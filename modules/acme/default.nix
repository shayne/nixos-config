{ config, lib, pkgs, ... }: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "cloudflare@shaynes.email";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialsFile =
        import ./cloudflareCredsFile.enc.nix { inherit pkgs; };
    };
  };

  # NOTE: This is the staging server, not the production server.
  # security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

  # Sleep for 5 seconds before starting the service to allow the network to
  # come up. This is a workaround for a DNS race condition.
  systemd.services = lib.mapAttrs'
    (name: _:
      lib.nameValuePair "acme-${name}" {
        serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      })
    config.security.acme.certs;
}
