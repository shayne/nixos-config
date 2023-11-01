{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "caddy";
  src = pkgs.fetchurl {
    url = "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&idempotency=74165303940021";
    sha256 = "sha256-cL//RApn0xiKjJulmlPg0hyZSmeXC9cjidfIxPAFTIo=";
    name = "caddy";
  };
  phases = [ "installPhase" "patchPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/caddy
    chmod +x $out/bin/caddy
  '';
}
