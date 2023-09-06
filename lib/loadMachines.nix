{ inputs, outputs, stateVersion, user, ... }:
# imports = map (n: "${./pkgConfigs}/${n}") (builtins.attrNames (builtins.readDir ./pkgConfigs));
# https://github.com/evanjs/nixos_cfg/blob/4bb5b0b84a221b25cf50853c12b9f66f0cad3ea4/config/new-modules/default.nix
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
