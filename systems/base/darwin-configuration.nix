{ config, lib, inputs, outputs, pkgs, ... }:
{
  # TODO: darwin error: boot does not exist
  # imports = [
  #   ../modules/services/tailscale.nix # unstable service override
  # ];

  # Only install the docs I use
  documentation = {
    enable = true;
    man.enable = true;
    info.enable = false;
    doc.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      gitMinimal
      gnumake
      home-manager
      killall
      niv
      rsync
      wget
    ];
    variables = {
      EDITOR = "vim";
      SYSTEMD_EDITOR = "vim";
      VISUAL = "vim";
    };
    # https://github.com/nix-community/home-manager/pull/2408
    pathsToLink = [ "/share/fish" ];
    shells = with pkgs; [ bashInteractive zsh fish ];
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.ubuntu-mono
      fira
      fira-go
      joypixels
      liberation_ttf
      noto-fonts-color-emoji
      source-serif
      ubuntu-classic
      work-sans
    ];
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      inputs.nixos-apple-silicon.overlays.apple-silicon-overlay

      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Accept the joypixels license
      joypixels.acceptLicense = true;
      permittedInsecurePackages = [
        "nix-2.15.3"
        "python3.11-youtube-dl-2021.12.17"
      ];
    };
  };

  nix = {
    optimise.automatic = true;

    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
      warn-dirty = false;
    };
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = true;
    user = config.system.primaryUser;
    taps = with inputs; {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
    };
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  system = {
    primaryUser = "shayne";
    activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
      '';
    };
  };
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
  users.users.shayne = {
    home = "/Users/shayne";
    shell = pkgs.fish;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true; # Show all file extensions
      NSUseAnimatedFocusRing = false; # Disable focus ring animation
      NSNavPanelExpandedStateForSaveMode = true; # Expand save dialog
      NSNavPanelExpandedStateForSaveMode2 = true; # Expand save dialog (v2)
      PMPrintingExpandedStateForPrint = true; # Expand print dialog
      PMPrintingExpandedStateForPrint2 = true; # Expand print dialog (v2)
      NSDocumentSaveNewDocumentsToCloud = false; # Save to disk by default
      ApplePressAndHoldEnabled = false; # Use key repeat (no accents)
      AppleKeyboardUIMode = 3; # Full keyboard access
      InitialKeyRepeat = 10; # Delay until repeat
      KeyRepeat = 2; # Key repeat rate
      NSAutomaticCapitalizationEnabled = false; # Disable auto-capitalization
      NSAutomaticDashSubstitutionEnabled = false; # Disable smart dashes
      NSAutomaticPeriodSubstitutionEnabled = false; # Disable double-space period
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quotes
      NSAutomaticSpellingCorrectionEnabled = false; # Disable autocorrect
      "com.apple.mouse.tapBehavior" = 1; # Tap-to-click
      NSWindowShouldDragOnGesture = true; # Cmd+Ctrl drag windows
    };
    LaunchServices.LSQuarantine = false; # Disable app quarantine prompt
    loginwindow.GuestEnabled = false; # Disable Guest login
    finder.FXPreferredViewStyle = "Nlsv"; # Finder default view (List)
    WindowManager.EnableStandardClickToShowDesktop = false; # Disable click-to-show-desktop
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true; # No .DS_Store on network volumes
      DSDontWriteUSBStores = true; # No .DS_Store on USB volumes
    };
    # Opinionated Dock defaults.
    "com.apple.dock" = {
      autohide = true; # Auto-hide Dock
      mru-spaces = false; # Don't rearrange Spaces
      launchanim = false; # Disable Dock launch animation
      static-only = false; # Show pinned + running apps
      show-recents = false; # Hide recent apps section
      show-process-indicators = true; # Show running app dots
      showhidden = true; # Translucent hidden apps
      orientation = "bottom"; # Dock position
      tilesize = 64; # Dock icon size
      minimize-to-application = true; # Minimize into app icon
      mineffect = "scale"; # Minimize animation style
      enable-window-tool = false; # Dock window tool (undocumented)
      # Example dock layout (disabled for now)
      # persistent-apps = [
      #   "/Applications/Google Chrome.app"
      #   "/Applications/Signal.app"
      #   "/Applications/Discord.app"
      #   "/Applications/Obsidian.app"
      #   "/Applications/Visual Studio Code.app"
      # ];
    };
    "com.apple.ActivityMonitor" = {
      OpenMainWindow = true; # Open main window on launch
      IconType = 5; # Dock icon: CPU usage meter
      SortColumn = "CPUUsage"; # Sort by CPU usage
      SortDirection = 0; # Sort order
    };
    "com.apple.Safari" = {
      UniversalSearchEnabled = false; # Don't send searches to Apple
      SuppressSearchSuggestions = true; # Disable search suggestions
    };
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false; # Disable personalized ads
    };
    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true; # Auto check for updates
      ScheduleFrequency = 1; # Check daily
      AutomaticDownload = 1; # Download updates automatically
      CriticalUpdateInstall = 1; # Install critical updates
    };
    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true; # Don't prompt for new disks
    };
    "com.apple.ImageCapture" = {
      disableHotPlug = true; # Stop Photos auto-launch on plug-in
    };
    "com.apple.commerce" = {
      AutoUpdate = true; # App Store auto-updates
    };
    "com.google.Chrome" = {
      AppleEnableSwipeNavigateWithScrolls = true; # Enable swipe back/forward
      DisablePrintPreview = true; # Use system print dialog
      PMPrintingExpandedStateForPrint2 = true; # Expand print dialog
    };
  };

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs = {
    zsh = {
      enable = true;
      shellInit = ''
        # Nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
        # End Nix
      '';
    };
    fish = {
      enable = true;
      shellInit = ''
        # Nix
        if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
          source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
        end
        # End Nix
      '';
    };
  };

  # Keep Homebrew in sync with declared brews/casks.
  homebrew.onActivation = {
    cleanup = "zap";
    autoUpdate = true;
    upgrade = true;
  };
}
