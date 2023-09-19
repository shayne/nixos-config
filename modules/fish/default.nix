{ inputs, outputs, user, stateVersion, myLibPath, lib, pkgs, sources, ... }:
let
  libx = import myLibPath { inherit inputs outputs user stateVersion; };
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]);

    inherit (libx) shellAliases;

    plugins = map
      (n: {
        name = n;
        src = sources.${n};
      }) [
      "fish-fzf"
      "fish-foreign-env"
      "zoxide.fish"
    ];
  };

  programs.starship = {
    enable = true;
    package = pkgs.unstable.starship;
    enableTransience = true;
    enableFishIntegration = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      gcloud.disabled = true;
    };
  };
}
