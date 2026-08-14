{ config, pkgs, ... }:
{
  home.file."Library/Application Support/com.mitchellh.ghostty/config.ghostty" = {
    force = true;
    text = ''
      theme = light:One Half Light,dark:Dracula PRO
      # theme = Tomorrow

      font-family = "BerkeleyMono Nerd Font"
      font-size = 15

      window-width = 100
      window-height = 30

      window-padding-x = 6
      window-padding-y = 6
      window-padding-balance = true

      macos-option-as-alt = true

      keybind = global:cmd+ctrl+t=toggle_quick_terminal

      shell-integration = fish

      cursor-invert-fg-bg = true
      keybind = shift+enter=text:\n
    '';
  };

  home.packages = with pkgs; [
    docker-client
    gnugrep
    nil
    yt-dlp

    unstable.devenv
  ];

  programs.fish = {
    shellAliases = {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };
  };

  sops.secrets = {
    ghostty_dracula_pro = { };
    linearmouse_config = { };
  };

  xdg.configFile."ghostty/themes/Dracula PRO" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ghostty_dracula_pro.path;
  };

  xdg.configFile."linearmouse/linearmouse.json" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.linearmouse_config.path;
  };
}
