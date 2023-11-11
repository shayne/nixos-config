{ pkgs, lib, myModulesPath, ... }: {

  imports = [
    (myModulesPath + "/hyprland/user.nix")
    (myModulesPath + "/i3")
    (myModulesPath + "/inputrc")
    (myModulesPath + "/kitty")
    (myModulesPath + "/xresources")
  ];

  home.packages = with pkgs; [
    dconf
    firefox
    gnome.nautilus
    scrot
    viewnior
    xdg-user-dirs

    unstable.telegram-desktop
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
  };

  programs.fish.shellAliases = {
    # ssh = "kitty +kitten ssh";
  };

  programs.i3status-rust = {
    enable = true;
    bars.default.blocks = [
      {
        block = "net";
        device = "wlp1s0f0";
        format = "{ssid} {signal_strength} {ip} {speed_down;K*b} {graph_down;K*b}";
        interval = 5;
      }
      {
        block = "battery";
        interval = 10;
        format = "{percentage:6#100} {percentage} {time}";
        device = "macsmc-battery";
      }
      {
        block = "disk_space";
        path = "/";
        alias = "/";
        info_type = "available";
        unit = "GB";
        interval = 60;
        warning = 20.0;
        alert = 10.0;
      }
      {
        block = "load";
        format = "1min avg: {1m}";
        interval = 1;
      }
      {
        block = "memory";
        format_mem = "{mem_used}/{mem_total}({mem_used_percents})";
        format_swap = "{swap_used}/{swap_total}({swap_used_percents})";
        display_type = "memory";
        icons = true;
        clickable = true;
        interval = 5;
        warning_mem = 80;
        warning_swap = 80;
        critical_mem = 95;
        critical_swap = 95;
      }
      {
        block = "time";
        format = "%a %d/%m %R";
        timezone = "US/Eastern";
        interval = 60;
        locale = "en_US";
      }
    ];
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      font = {
        normal = {
          family = "BerkeleyMono Nerd Font";
        };
        size = 12;
      };

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Minus"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      golang.go
      bbenoist.nix
      arrterian.nix-env-selector
    ];
  };

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = {
    x11.enable = true;
    name = "Vanilla-DMZ-AA";
    package = pkgs.vanilla-dmz;
    size = 32;
  };

  services = {
    xcape.enable = true;

    network-manager-applet.enable = true;
    blueman-applet.enable = true;
    pasystray.enable = true;
  };


  systemd.user.services.barrierc.Install.WantedBy = lib.mkForce [ ];

  # barrier.client = {
  #   enable = true;
  #   server = "desktop:24800";
  #   enableCrypto = false;
  #   extraFlags = [ "--disable-crypto" "-f" ];
  # };
}
