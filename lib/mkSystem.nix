{ name, inputs, outputs, stateVersion }:
let
  inherit (inputs.nixpkgs) lib;
  myLibPath = ../lib;
  systemsPath = ../systems;
  myModulesPath = ../modules;
  homeManagerPath = ../home-manager;
  filterDirs = lib.filterAttrs (_n: v: v == "directory");
  userDirs =
    builtins.attrNames
      (filterDirs (builtins.readDir homeManagerPath));
  usersForSystem =
    name: lib.flatten
      (builtins.map
        (user:
        (builtins.map (_v: user)
          (builtins.filter (n: n == name)
            (builtins.attrNames (filterDirs (builtins.readDir (homeManagerPath + "/${user}")))))))
        userDirs);
  users = usersForSystem name;
  isDarwin = builtins.pathExists (systemsPath + "/${name}/darwin-configuration.nix");
  configFile = if isDarwin then "darwin-configuration.nix" else "configuration.nix";
  configKey = if isDarwin then "darwinConfigurations" else "nixosConfigurations";
  systemFn = if isDarwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  homeManagerFn = if isDarwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;
  baseSystemConfig = systemsPath + "/base/${(if isDarwin then "darwin-configuration.nix" else "nixos-configuration.nix")}";
  args = {
    inherit users myLibPath myModulesPath;
    currentSystemName = name;
    sources = import ../nix/sources.nix;
    unstableModulesPath = "${inputs.home-manager-unstable.outPath}";
  };
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
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
        home-manager.users = recursiveMergeAttrs (builtins.map
          (user: {
            ${user} = inputs.nixpkgs.lib.mkMerge ([
              inputs.plasma-manager.homeManagerModules.plasma-manager
              (import homeManagerPath)
              (import (homeManagerPath + "/${user}"))
            ] ++ lib.optionals (builtins.pathExists (homeManagerPath + "/${user}/${name}")) [
              (import (homeManagerPath + "/${user}/${name}"))
            ]);
          })
          users);
      }
    ] ++ builtins.map
      (user:
        if !isDarwin && (builtins.pathExists (homeManagerPath + "/${user}/nixos-configuration.nix")) then
          import (homeManagerPath + "/${user}/nixos-configuration.nix")
        else { }
      )
      users;

    specialArgs = {
      inherit inputs outputs stateVersion users myLibPath myModulesPath;
      currentSystemName = name;
    };
  };
}
