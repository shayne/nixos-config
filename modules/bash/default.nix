{ inputs, outputs, user, stateVersion, myLibPath, ... }:
let
  libx = import myLibPath { inherit inputs outputs user stateVersion; };
in
{
  programs.bash = {
    enable = true;
    shellOptions = [ ];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;

    inherit (libx) shellAliases;
  };
}
