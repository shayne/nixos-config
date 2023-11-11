{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    xkbOptions = "ctrl:nocaps";

    desktopManager.plasma5.enable = true;
    displayManager = {
      sddm.enable = true;

      # Keyboard repeat rate
      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
      '';
    };
  };
  # services.xserver.displayManager.defaultSession = "plasmawayland";

  # Console TTY uses XKB configuration too
  console.useXkbConfig = true;

  # GTK themes in Wayland applications
  programs.dconf.enable = true;
  # environment.plasma5.excludePackages = with pkgs.libsForQt5; [
  #   konsole
  #   plasma-browser-integration
  # ];
}
