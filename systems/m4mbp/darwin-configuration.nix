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

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    systemBuilderArgs = lib.mkIf (config.nix.settings.sandbox == "relaxed") {
      sandboxProfile = ''
        (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
      '';
    };
    defaults = {
      NSGlobalDomain = {
        # Disable press-and-hold for keys in favor of key repeat
        ApplePressAndHoldEnabled = false;
        # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
        AppleKeyboardUIMode = 3;
        # Set a shorter Delay until key repeat
        InitialKeyRepeat = 10;
        # Set a blazingly fast keyboard repeat rate
        KeyRepeat = 2;
        # Automatic text replacement settings
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        # Expand save panel by default
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        # Expand print panel by default
        PMPrintingExpandedStateForPrint = true;
        # Hide the menubar
        # _HIHideMenuBar = true;
      };
      dock = {
        autohide = true;
        mru-spaces = false;
        showhidden = true;
      };
      finder = {
        AppleShowAllExtensions = true;
      };
      WindowManager = {
        # Disable click to show desktop
        EnableStandardClickToShowDesktop = false;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    stateVersion = 5;
  };

  programs.nix-index.enable = true;

  homebrew = {
    enable = true;
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
      "zsync"
    ];
    casks = [
      "arc"
      "anytype"
      "audacity"
      "bambu-studio"
      "bartender"
      "bentobox"
      "chatgpt"
      "claude"
      "cursor"
      "deskpad"
      "discord"
      "diffusionbee"
      "google-chrome"
      "homerow"
      "inkscape"
      "iterm2"
      "linearmouse"
      "lunar"
      "multipass"
      "multiviewer"
      "ollama-app"
      "orbstack"
      "pearcleaner"
      "raycast"
      "screen-studio"
      "shortcat"
      "shureplus-motiv"
      "signal"
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
