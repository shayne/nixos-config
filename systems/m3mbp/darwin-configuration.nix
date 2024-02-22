_: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    enable = true;
    brews = [
      "lima"
    ];
    casks = [
      # "1password"
      # "alfred"
      # "amethyst"
      # "cleanshot"
      "discord"
      # "google-chrome"
      # "imageoptim"
      # "istat-menus"
      "linearmouse"
      "maccy"
      # "macfuse"
      # "monodraw"
      "raycast"
      "rectangle"
      # "screenflow"
      # "slack"
      "signal"
      # "spotify"
      "syncthing"
    ];
  };

  services.tailscale.enable = true;

  launchd.daemons.ttl65.serviceConfig = {
    RunAtLoad = true;
    UserName = "root";
    GroupName = "wheel";
    Program = "/usr/sbin/sysctl";
    ProgramArguments = [ "/usr/sbin/sysctl" "net.inet.ip.ttl=65" "net.inet6.ip6.hlim=65" ];
  };
}
