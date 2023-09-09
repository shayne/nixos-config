{ inputs, outputs, stateVersion, user, ... }:
let
  inherit (inputs.nixpkgs) lib;
  systemsDir = ../systems;
  machineDirs =
    lib.mapAttrsToList (n: _v: n)
      (lib.filterAttrs (_n: v: v == "directory")
        (builtins.readDir systemsDir));
  systemConfigs = map (name: (import ./mkSystem.nix { inherit name user inputs outputs stateVersion; })) machineDirs;
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
in
# recursiveMergeAttrs systems
recursiveMergeAttrs systemConfigs
