{ pkgs, ... }:

{
  home.packages = [ pkgs.inter ];

  services.dunst = {
    enable = true;
    iconTheme = {
      name = "Fluent-dark";
      package = pkgs.fluent-icon-theme;
    };
    settings = {
      global = {
        font = "Inter 12";
        frame_color = "#100E23";
        frame_width = "2";
        origin = "top-right";
        offset = "8x4";
        width = "300";
        height = "200";
        padding = 16;
        horizontal_padding = 16;
        separator_color = "#585273";
      };

      urgency_low = {
        background = "#2D2B40";
      };

      urgency_normal = {
        background = "#2D2B40";
      };

      urgency_high = {
        background = "#2D2B40";
      };

      discord = {
        appname = "Discord";
        urgency = "low";
      };
    };
  };
}
