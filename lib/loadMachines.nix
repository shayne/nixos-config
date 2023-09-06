{ inputs, outputs, stateVersion, user, ... }:
path:
let
  inherit (inputs.nixpkgs) lib;
  mkSystem = import ./mkSystem.nix { inherit user inputs outputs stateVersion; };
  mkDarwin = import ./mkDarwin.nix { inherit user inputs outputs stateVersion; };
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
  systems = lib.mapAttrsToList
    (name: attrs:
      if attrs.system or null == "aarch64-darwin" then
        { darwinConfigurations = mkDarwin { inherit name attrs; }; }
      else
        { nixosConfigurations = mkSystem { inherit name attrs; }; })
    (import path);
in
recursiveMergeAttrs systems
