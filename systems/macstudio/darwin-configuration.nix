{
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macstudio";

  system.stateVersion = 5;

  homebrew = {
    enable = true;
    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
