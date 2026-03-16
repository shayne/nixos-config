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

  security.sudo.extraConfig = ''
    shayne ALL = (ALL) NOPASSWD: ALL
  '';

  homebrew = {
    enable = true;
    taps = [ "steipete/tap" ];
    brews = [
      "mise"
      "steipete/tap/gogcli"
      "steipete/tap/peekaboo"
      "signal-cli"
      "uv"
    ];
    casks = [ ];
    masApps = { };
  };
}
