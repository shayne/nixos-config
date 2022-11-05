{ pkgs, lib, ... }: {

  home.file.".inputrc".source = ./inputrc;

  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  # xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;

  home.packages = (with pkgs; [
    dconf
    gnome.nautilus
    rofi
    scrot
    tdesktop
    viewnior
    wireguard-tools
    xdg-user-dirs
  ]);

  gtk = {
      enable = true;
      theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
      };
  };

  programs.fish.shellAliases = {
    ssh = "kitty +kitten ssh";
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status-rust = {
    enable = true;
    bars.default.blocks = [
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
  home.pointerCursor = {
    name = "Vanilla-DMZ-AA";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };

  services = {
    xcape.enable = true;
  };


  systemd.user.services.barrierc.Install.WantedBy = lib.mkForce [];

  # barrier.client = {
  #   enable = true;
  #   server = "desktop:24800";
  #   enableCrypto = false;
  #   extraFlags = [ "--disable-crypto" "-f" ];
  # };
}