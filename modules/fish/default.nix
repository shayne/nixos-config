{ inputs, outputs, user, stateVersion, myLibPath, lib, pkgs, ... }:
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

    plugins = [
      {
        name = "fish-fzf";
        src = inputs.fish-fzf;
      }
      {
        name = "fish-foreign-env";
        src = inputs.fish-foreign-env;
      }
      {
        name = "zoxide.fish";
        src = inputs.zoxide-fish;
      }
    ];
  };

  programs.starship = {
    enable = true;
    package = pkgs.unstable.starship;
    enableTransience = true;
    enableFishIntegration = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      container.disabled = true;
      gcloud.disabled = true;
    };
  };
}
