{ lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macstudio";

  nix = {
    # Determinate provides and manages Nix itself on this host.
    enable = lib.mkForce false;
    optimise.automatic = lib.mkForce false;
    gc.automatic = lib.mkForce false;
  };

  system.stateVersion = 5;

  homebrew = {
    enable = true;
    brews = [
      "mise"
      "signal-cli"
      "uv"
    ];
    casks = [ ];
    masApps = { };
  };
}
