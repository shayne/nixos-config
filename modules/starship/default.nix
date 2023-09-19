{ modulesPath, unstableModulesPath, ... }:
{
  disabledModules = [ "${modulesPath}/programs/starship.nix" ];

  imports = [
    "${unstableModulesPath}/modules/programs/starship.nix"
  ];
}
