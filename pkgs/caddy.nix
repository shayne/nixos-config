{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
  name = "caddy";
  src = pkgs.fetchurl {
    url = "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&idempotency=74165303940021";
    sha256 = "1jfflkw2wvbdlyr2ikgq9lxa9130z00nyf9r883l7z59wyhyn0y9";
    name = "caddy";
  };
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/caddy
      chmod +x $out/bin/caddy
  '';
}
