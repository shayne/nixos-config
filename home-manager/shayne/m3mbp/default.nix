{ myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/rectangle")
  ];
}