{ inputs, outputs, stateVersion, user, ... }:
path:
let
  inherit (inputs.nixpkgs) lib;
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
  mkSystem = import ./mkSystem.nix { inherit user inputs outputs stateVersion; };
  systems = lib.mapAttrsToList
    (name: attrs: mkSystem { inherit name attrs; })
    (import path);
in
recursiveMergeAttrs (map
  (s: {
    nixosConfigurations = s;
  })
  systems)
