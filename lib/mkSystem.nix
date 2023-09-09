{ name, inputs, outputs, stateVersion, user }:
let
  systemsDir = ../systems;
  inherit (inputs.nixpkgs) lib;
  args = {
    inherit user;
    currentSystemName = name;
    myModulesPath = ../home-manager/modules;
    sources = import ../nix/sources.nix;
  };
  isDarwin = builtins.pathExists (systemsDir + "/${name}/darwin-configuration.nix");
  configFile = if isDarwin then "darwin-configuration.nix" else "configuration.nix";
  configKey = if isDarwin then "darwinConfigurations" else "nixosConfigurations";
  systemFn = if isDarwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  homeManagerFn = if isDarwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;
in
{
  ${configKey}.${name} = systemFn {
    modules = [
      ../nixos
      systemsDir
      (systemsDir + "/${name}/${configFile}")
    ] ++ lib.optionals (builtins.pathExists "${systemsDir}/${name}/hardware.nix") [
      (systemsDir + "/${name}/hardware.nix")
    ] ++ [
      homeManagerFn
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = args;
        home-manager.users.${user} = inputs.nixpkgs.lib.mkMerge [
          (import ../home-manager)
          (import ../home-manager/${user})
          (import ../home-manager/${user}/${name})
        ];
      }
    ];

    specialArgs = {
      inherit inputs outputs stateVersion user;
      currentSystemName = name;
    };
  };
}
