{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "caddy";
  src = pkgs.fetchurl {
    url = "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&idempotency=74165303940021";
    sha256 = "sha256-7WFzmep/bmoikBD0IwG6tzJcvHylO4NTCvHux/UAjO8";
    name = "caddy";
  };
  phases = [ "installPhase" "patchPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/caddy
    chmod +x $out/bin/caddy
  '';
}
