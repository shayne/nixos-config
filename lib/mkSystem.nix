{ name, inputs, outputs, stateVersion, user }:
let
  inherit (inputs.nixpkgs) lib;
  myLibPath = ../lib;
  myModulesPath = ../modules;
  systemsPath = ../systems;
  args = {
    inherit user myLibPath myModulesPath;
    currentSystemName = name;
    sources = import ../nix/sources.nix;
  };
  isDarwin = builtins.pathExists (systemsPath + "/${name}/darwin-configuration.nix");
  configFile = if isDarwin then "darwin-configuration.nix" else "configuration.nix";
  configKey = if isDarwin then "darwinConfigurations" else "nixosConfigurations";
  systemFn = if isDarwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  homeManagerFn = if isDarwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;
  baseSystemConfig = systemsPath + "/base/${(if isDarwin then "darwin-configuration.nix" else "nixos-configuration.nix")}";
in
{
  ${configKey}.${name} = systemFn {
    modules = [
      baseSystemConfig
      systemsPath
      (systemsPath + "/${name}/${configFile}")
    ] ++ lib.optionals (builtins.pathExists "${systemsPath}/${name}/hardware.nix") [
      (systemsPath + "/${name}/hardware.nix")
    ] ++ [
      homeManagerFn
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = args;
        home-manager.users.${user} = inputs.nixpkgs.lib.mkMerge ([
          (import ../home-manager)
          (import ../home-manager/${user})
        ] ++ lib.optionals (builtins.pathExists (../home-manager + "/${user}/${name}")) [
          (import ../home-manager/${user}/${name})
        ]);
      }
    ];

    specialArgs = {
      inherit inputs outputs stateVersion user myLibPath myModulesPath;
      currentSystemName = name;
    };
  };
}
