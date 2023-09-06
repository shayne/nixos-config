{ inputs, outputs, stateVersion, user, ... }:
path:
let
  inherit (inputs.nixpkgs) lib;
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
  mkSystem = import ./mkSystem.nix { inherit user inputs outputs stateVersion; };
in
recursiveMergeAttrs (map (s: { nixosConfigurations = mkSystem s; }) (import path))
