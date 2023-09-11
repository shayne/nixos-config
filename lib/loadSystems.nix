{ inputs, outputs, stateVersion, ... }:
let
  inherit (inputs.nixpkgs) lib;
  systemsDir =
    builtins.attrNames
      (lib.filterAttrs (_n: v: v == "directory")
        (builtins.readDir ../systems));
  systemConfigs = map (name: (import ./mkSystem.nix { inherit name inputs outputs stateVersion; })) systemsDir;
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
in
recursiveMergeAttrs systemConfigs
