{ lib, inputs, overlays, user }:

with lib;
with inputs;

let
  _overlays = overlays;
in

{ name, system, overlays ? [ ] }:

let
  args = {
    inherit user inputs;
    currentSystemName = name;
    currentSystem = system;
  };
in
{
  ${name} = nix-darwin.lib.darwinSystem {
    inherit system;

    modules = [

      { nixpkgs.overlays = _overlays ++ overlays; }

      ../machines/shared.nix
      ../machines/${name}.nix
      ../users/${user}/darwin.nix

      home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = args;
        home-manager.users.${user} = lib.mkMerge [
          (import ../users/${user}/home-manager-shared.nix)
          (import ../users/${user}/home-manager.${name}.nix)
        ];
      }

      {
        config._module.args = args;
      }
    ];

    specialArgs = { inherit inputs; };
  };
}
