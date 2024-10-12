{ config, lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.sandbox = "relaxed";
  nix.settings.extra-sandbox-paths = [
    "/private/var/db/oah" # aot files
    "/Library/Apple" # rossetta runtime
  ];
  nix.settings.trusted-users = [ "@admin" ];

  nix.linux-builder = {
    enable = true;
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

  security.pam.enableSudoTouchIdAuth = true;

  system.systemBuilderArgs = lib.mkIf (config.nix.settings.sandbox == "relaxed") {
    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
    '';
  };


  homebrew = {
    enable = true;
    brews = [
      "bash"
      "cdrtools"
      "coreutils"
      "gnu-tar"
      "jq"
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
      "bentobox"
      "chatgpt"
      "cursor"
      "deskpad"
      "discord"
      "grammarly-desktop"
      "inkscape"
      "iterm2"
      "linearmouse"
      "lunar"
      "microsoft-remote-desktop"
      "multipass"
      "multiviewer-for-f1"
      "orbstack"
      "pearcleaner"
      "raycast"
      "screen-studio"
      "shureplus-motiv"
      "signal"
      "slack"
      "steam"
      "swiftformat-for-xcode"
      "syncthing"
      # This freezes on quit, using desktop.telegram.org for now
      # "telegram-desktop"
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
  # Disable press-and-hold for keys in favor of key repeat
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  # Set a shorter Delay until key repeat
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  # Set a blazingly fast keyboard repeat rate
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  # Automatic text replacement settings
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  # Expand save panel by default
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
  # Expand print panel by default
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
  # Hide the menubar
  # system.defaults.NSGlobalDomain._HIHideMenuBar = true;
  # Dock setting
  system.defaults.dock.autohide = true;
  system.defaults.dock.mru-spaces = false;
  system.defaults.dock.showhidden = true;
  # Show all filename extensions
  system.defaults.finder.AppleShowAllExtensions = true;
  # Keyboard settings
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  # Disable click to show desktop
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;
}
