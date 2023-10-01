{
  programs.plasma = {
    enable = true;
    configFile = {
      "kcminputrc"."Keyboard"."RepeatDelay" = 225;
      "kcminputrc"."Keyboard"."RepeatRate" = 60;
      "kcminputrc"."Libinput.1452.849.Apple MTP multi-touch"."NaturalScroll" = true;
      "kcminputrc"."Libinput.1452.849.Apple MTP multi-touch"."ScrollFactor" = 0.5;
      "kcminputrc"."Mouse"."cursorTheme" = "Vanilla-DMZ-AA";
    };
  };
}
