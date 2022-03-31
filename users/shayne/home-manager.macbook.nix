{ pkgs, ... }: {

  imports = [
    ./home-manager-shared.nix
  ];

  home.file.".inputrc".source = ./inputrc;

  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;

  home.packages = (with pkgs; [
    tdesktop
    wireguard-tools
    rofi
    dconf
  ]);

  gtk = {
      enable = true;
      theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
      };
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status = {
    enable = true;
    enableDefault = false;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      "wireless _first_" = {
        position = 2;
        settings = {
          format_up = "W: (%quality at %essid) %ip";
          format_down = "W: down";
        };
      };
      "battery 0" = {
         position = 4;
         settings = {
           format = "%status %percentage %remaining %emptytime";
           format_down = "No battery";
           status_chr = "⚡ CHR";
           status_bat = "🔋 BAT";
           status_unk = "? UNK";
           status_full = "☻ FULL";
           path = "/sys/class/power_supply/macsmc-battery/uevent";
           low_threshold = 10;
         };
      };
      "disk /" = {
        position = 5;
        settings = {
          format = "%avail";
        };
      };
      load= {
        position = 6;
        settings = {
          format = "%1min";
        };
      };
      memory = {
        position = 7;
        settings = {
          format = "%used | %available";
          threshold_degraded = "1G";
          format_degraded = "MEMORY < %available";
        };
      };
      "tztime local" = {
        position = 8;
        settings = { format = "%Y-%m-%d %H:%M:%S"; };
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      golang.go
      bbenoist.nix
      arrterian.nix-env-selector
    ];
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  xsession.pointerCursor = {
    name = "Vanilla-DMZ-AA";
    package = pkgs.vanilla-dmz;
    size = 32;
  };

  services.xcape.enable = true;
}
