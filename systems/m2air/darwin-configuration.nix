_: {

  homebrew = {
    enable = true;
    brews = [
      "lima"
    ];
    casks = [
      # "1password"
      # "alfred"
      "amethyst"
      "cleanshot"
      "discord"
      # "google-chrome"
      # "imageoptim"
      "istat-menus"
      "maccy"
      # "monodraw"
      "raycast"
      "rectangle"
      # "screenflow"
      # "slack"
      "signal"
      "spotify"
      "syncthing"
    ];
  };

  services.tailscale.enable = true;
}
