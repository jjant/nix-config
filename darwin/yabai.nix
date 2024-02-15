{lib, ...}: {
  services.yabai.enable = true;
  services.yabai.enableScriptingAddition = true;
  # services.yabai.extraConfig = builtins.trace (lib.readFile ./yabairc) (lib.readFile ./yabairc);
  services.yabai.config = {
    layout = "bsp";
    top_padding         = 5;
    bottom_padding      = 5;
    left_padding        = 5;
    right_padding       = 5;
    window_gap          = 5;
    window_opacity      = "off";
  };
  services.yabai.extraConfig = ''
    yabai -m rule --add app='System Settings' manage=off
  '';
}
