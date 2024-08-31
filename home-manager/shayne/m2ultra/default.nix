{ pkgs, myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/rectangle")
  ];

  home.packages = with pkgs; [
    docker-client
    gnugrep
    youtube-dl
  ];

  programs.fish = {
    shellAliases = {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };
  };
}
