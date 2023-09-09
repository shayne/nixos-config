{ pkgs, ... }:
let
  shellAliases = {
    open = "wslview";
    pbcopy = "clip.exe";
    pbpaste = "powershell.exe Get-Clipboard";
    # clear = "powershell.exe Clear-Host";
  };
in
{

  home.sessionVariables = {
    BROWSER = "wslview";
  };

  home.packages = with pkgs; [
    unstable.wslu
  ];

  programs.bash.shellAliases = shellAliases;
  programs.fish.shellAliases = shellAliases;
}
