{ inputs, outputs, user, stateVersion, ... }:
{
  loadSystems = import ./loadSystems.nix { inherit inputs outputs user stateVersion; };
  shellAliases = import ./shellAliases.nix;
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
