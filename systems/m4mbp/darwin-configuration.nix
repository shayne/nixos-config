{ config, lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "m4mbp";

  nix = {
    settings = {
      sandbox = "relaxed";
      extra-sandbox-paths = [
        "/private/var/db/oah" # aot files
        "/Library/Apple" # rossetta runtime
      ];
      trusted-users = [ "@admin" ];
    };
    linux-builder = {
      # Disabled as this does not work with the determinate nix-installer
      enable = false;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 6;
        };
      };
    };
  };

  system = {
    systemBuilderArgs = lib.mkIf (config.nix.settings.sandbox == "relaxed") {
      sandboxProfile = ''
        (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
      '';
    };
    stateVersion = 5;
  };

  programs.nix-index.enable = true;

  homebrew = {
    enable = true;
    taps = [
      "homebrew/cask"
      "homebrew/core"
      "homebrew/bundle"
    ];
    brews = [
      "bash"
      "cdrtools"
      "coreutils"
      "gnu-tar"
      "jq"
      "llama.cpp"
      "mise"
      "python3"
      "qemu"
      "samba"
      "socat"
      "swiftlint"
      "swtpm"
      "usbutils"
      "uv"
      "zsync"
    ];
    casks = [
      "audacity"
      "bambu-studio"
      "bentobox"
      "caffeine"
      "chatgpt"
      "claude"
      "cursor"
      "deskpad"
      "discord"
      "google-chrome"
      "homerow"
      "inkscape"
      "linearmouse"
      "lunar"
      "multiviewer"
      "orbstack"
      "portalbox"
      "raycast"
      "screen-studio"
      "shureplus-motiv"
      "signal"
      "spotify"
      "stats"
      "steam"
      "swiftformat-for-xcode"
      "tailscale-app"
      # This freezes on quit, using desktop.telegram.org for now
      # "telegram-desktop"
      "upscayl"
      "utm"
      "visual-studio-code"
      "vlc"
    ];
    masApps = {
      "Xcode" = 497799835;
    };
  };

  launchd.daemons.ttl65.serviceConfig = {
    RunAtLoad = true;
    UserName = "root";
    GroupName = "wheel";
    Program = "/usr/sbin/sysctl";
    ProgramArguments = [ "/usr/sbin/sysctl" "net.inet.ip.ttl=65" "net.inet6.ip6.hlim=65" ];
  };

  # more https://gist.github.com/DAddYE/2108403
}
