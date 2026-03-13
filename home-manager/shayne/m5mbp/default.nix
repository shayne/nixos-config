{ pkgs, myModulesPath, ... }:
{
  imports = [
    (myModulesPath + "/rectangle")
  ];

  home.packages = with pkgs; [
    docker-client
    gnugrep
    nil
    yt-dlp

    unstable.devenv
  ];

  programs.fish = {
    shellAliases = {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };
  };
}
