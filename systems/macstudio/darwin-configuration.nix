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
      "bitwarden-cli"
      "gh"
      "henrygd/beszel/beszel-agent"
      "mise"
      "openclaw-cli"
      "sichengchen/tap/apple-calendar-cli"
      "steipete/tap/gogcli"
      "steipete/tap/peekaboo"
      "signal-cli"
      "uv"
    ];
    casks = [
      "ngrok"
      "orbstack"
    ];
    masApps = {
      "Xcode" = 497799835;
    };
  };
}
