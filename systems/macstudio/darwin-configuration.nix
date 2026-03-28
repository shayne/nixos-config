_: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macstudio";

  system.stateVersion = 5;

  security.sudo.extraConfig = ''
    shayne ALL = (ALL) NOPASSWD: ALL
  '';

  homebrew = {
    enable = true;
    taps = [
      "henrygd/beszel"
      "homebrew/cask"
      "steipete/tap"
      "sichengchen/tap"
    ];
    brews = [
      "gh"
      "henrygd/beszel/beszel-agent"
      "mise"
      "sichengchen/tap/apple-calendar-cli"
      "steipete/tap/gogcli"
      "steipete/tap/peekaboo"
      "signal-cli"
      "uv"
    ];
    casks = [ "orbstack" ];
    masApps = {
      "Xcode" = 497799835;
    };
  };
}
