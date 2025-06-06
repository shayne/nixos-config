{ pkgs, inputs, ... }:
{
  imports = [
    ./dunst.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    grim
    hyprpicker
    light
    neofetch
    # playerctl
    slurp
    swaybg
    wl-clipboard
    wofi-emoji

    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
  ];

  # xdg.dataFile."wallpaper/1e1c31.png".source = ../1e1c31.png;
  # xdg.dataFile."wallpaper/light.png".source = ../light.JPG;

  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   extraConfig = import ./config.nix;
  #   xwayland.enable = true;
  # };

  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   # xwayland.enable = true;
  # };

  xdg.configFile."hypr/hyprland.conf".text = builtins.readFile ./hyprland.conf;

  programs.wofi.enable = true;
  programs.waybar.enable = true;
}
