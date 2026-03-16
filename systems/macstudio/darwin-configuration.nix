_: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macstudio";

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
