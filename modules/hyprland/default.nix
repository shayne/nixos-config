{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    xkbOptions = "ctrl:nocaps";
    displayManager = {
      gdm.enable = true;
      # Keyboard repeat rate
      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
      '';
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
