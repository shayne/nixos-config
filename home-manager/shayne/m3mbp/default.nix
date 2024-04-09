{ pkgs, myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/rectangle")
  ];

  home.packages = with pkgs; [
    docker-client
  ];
}
