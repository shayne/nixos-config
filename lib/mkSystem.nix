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
  ${name} = nixosSystem {
    inherit system;

    modules = [

      { nixpkgs.overlays = _overlays ++ overlays; }

      ../hardware/${name}.nix
      ../machines/shared.nix
      ../machines/shared-linux.nix
      ../machines/${name}.nix
      ../users/${user}/nixos.nix

      home-manager.nixosModules.home-manager
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
