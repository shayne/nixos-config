{ inputs, outputs, user, stateVersion }:

{ name, system }:

let
  args = {
    inherit user;
    currentSystemName = name;
    currentSystem = system;
  };
in
{
  ${name} = inputs.nix-darwin.lib.darwinSystem {
    inherit system;

    modules = [
      ../nix-darwin
      ../machines/${name}.nix

      inputs.home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = args;
        home-manager.users.${user} = inputs.nixpkgs.lib.mkMerge [
          (import ../users/${user}/home-manager-shared.nix)
          (import ../users/${user}/home-manager.${name}.nix)
        ];
      }
    ];

    specialArgs = {
      inherit inputs outputs stateVersion user;
      currentSystemName = name;
      currentSystem = system;
    };
  };
}
