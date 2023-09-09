let
  libx = import ../../lib;
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
