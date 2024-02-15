{
  pkgs,
  config,
  lib,
  ...
}: {
  services.skhd = {
    enable = true;
    skhdConfig = ''
      ctrl - 1 : yabai -m space --focus 1
      ctrl - 2 : yabai -m space --focus 2
      ctrl - 3 : yabai -m space --focus 3
      ctrl - 4 : yabai -m space --focus 4
      ctrl - 5 : yabai -m space --focus 5
      ctrl - 6 : yabai -m space --focus 6
      ctrl - 7 : yabai -m space --focus 7
      ctrl - 8 : yabai -m space --focus 8
      ctrl - 9 : yabai -m space --focus 9
    '';
  };
}
