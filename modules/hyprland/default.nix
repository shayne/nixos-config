{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    xkbOptions = "ctrl:nocaps";

    displayManager = {
      gdm.enable = true;
      gdm.wayland = true;
      # Keyboard repeat rate
      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
      '';
    };

    windowManager.awesome.enable = true;
  };

  console.useXkbConfig = true;

  programs.hyprland = {
    enable = true;
    # package = pkgs.unstable.hyprland;
    xwayland.enable = true;
  };

  # GTK themes in Wayland applications
  programs.dconf.enable = true;
}
