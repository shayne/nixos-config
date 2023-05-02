{ pkgs, ... }:

{
  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix)
  ];

  homebrew = {
    enable = true;
    casks  = [
      # "1password"
      # "alfred"
      "cleanshot"
      # "discord"
      # "google-chrome"
      # "imageoptim"
      "istat-menus"
      # "monodraw"
      "rectangle"
      # "screenflow"
      # "slack"
      # "spotify"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.shayne = {
    home = "/Users/shayne";
    shell = pkgs.fish;
  };
}
