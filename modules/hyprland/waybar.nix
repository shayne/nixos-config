{ pkgs, ... }:

{

  home.packages = [ pkgs.inter ];

  services.playerctld.enable = true;

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: { mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ]; });
    settings = {
      mainBar = {
        margin = "0";
        layer = "top";
        modules-left = [ "custom/nix" "wlr/workspaces" "mpris" ];
        modules-center = [ "wlr/taskbar" ];
        modules-right = [ "custom/task-context" "network#interface" "network#speed" "cpu" "temperature" "backlight" "battery" "clock" "custom/notification" "tray" ];

        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
        };

        "wlr/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          sort-by-number = true;
          format-icons = {
            "1" = "";
            "2" = "󰈹";
            "3" = "󰒱";
            "4" = "󰴸";
          };
        };

        mpris = {
          format = "{status_icon}<span weight='bold'>{artist}</span> | {title}";
          status-icons = {
            playing = "󰎈 ";
            paused = "󰏤 ";
            stopped = "󰓛 ";
          };
        };

        "custom/nix" = {
          format = "󱄅 ";
        };

        "wlr/taskbar" = {
          on-click = "activate";
        };

        "custom/task-context" = {
          exec = "~/.config/waybar/scripts/task-context.sh";
          tooltip = false;
          on-click = "task @ none";
          restart-interval = 1;
        };

        "network#interface" = {
          format-ethernet = "󰣶  {ifname}";
          format-wifi = "󰖩 {ifname}";
          tooltip = true;
          tooltip-format = "{ipaddr}";
        };

        "network#speed" = {
          format = "⇡{bandwidthUpBits} ⇣{bandwidthDownBits}";
        };

        cpu = {
          format = "  {usage}% 󱐌 {avg_frequency}";
        };

        temperature = {
          format = "{icon} {temperatureC} °C";
          format-icons = [ "" "" "" "󰈸" ];
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [ "󰃜" "󰃛" "󰃚 " ];
        };

        battery = {
          format-critical = "{icon} {capacity}%";
          format = "{icon} {capacity}%";
          format-icons = [ "󰁺" "󰁾" "󰂀" "󱟢" ];
        };

        clock = {
          format = "   {:%H:%M}";
          format-alt = "󰃭  {:%Y-%m-%d}";
        };

        "custom/notification" = {
          exec = "~/.config/waybar/scripts/dunst.sh";
          tooltip = false;
          on-click = "dunstctl set-paused toggle";
          restart-interval = 1;
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        min-height: 0;
      }

      window#waybar {
        font-family: 'Inter', 'RobotoMono Nerd Font';
        font-size: 12px;
      }

      tooltip {
      }

      #custom-nix {
        padding: 2px 6px;
      }

      #workspaces button {
        padding: 2px 6px;
        margin: 0 6px 0 0;
      }

      .modules-right * {
        padding: 0 6px;
        margin: 0 0 0 4px;
      }

      #mpris {
        padding: 0 6px;
      }

      #custom-notification {
        padding: 0 6px 0 6px;
      }

      #tray {
        padding: 0 6px;
      }
      
      #tray * {
        padding: 0;
        margin: 0;
      }
    '';
  };

  xdg.configFile."waybar/scripts/dunst.sh" = {
    text = ''
      COUNT=$(dunstctl count waiting)
      ENABLED="󰂚 "
      DISABLED="󰂛 "
      if [ $COUNT != 0 ]; then DISABLED="󱅫 "; fi
      if dunstctl is-paused | grep -q "false"; then
        echo $ENABLED
      else
        echo $DISABLED
      fi
    '';
    executable = true;
  };

  xdg.configFile."waybar/scripts/task-context.sh" = {
    text = ''
      ICON=" "
      CONTEXT=$(task _get rc.context)

      if [ -z "$CONTEXT" ]; then
        CONTEXT="NONE"
      fi
      echo "$ICON  $CONTEXT"
    '';
    executable = true;
  };
}

