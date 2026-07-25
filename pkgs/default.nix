# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { }, ... }: {
  caddy = pkgs.callPackage ../pkgs/caddy.nix { };
  tui-use = pkgs.callPackage ../pkgs/tui-use.nix { };
  umbra = pkgs.callPackage ../pkgs/umbra.nix { };
}
