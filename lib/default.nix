{ inputs, outputs, user, stateVersion, ... }:
{
  loadMachines = import ./loadMachines.nix { inherit inputs outputs user stateVersion; };
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
