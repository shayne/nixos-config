{ inputs, ... }:
{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/tailscale.nix"
  ];
}
