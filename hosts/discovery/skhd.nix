{
  # I should use the `nix-darwin` module for this
  # when I move my osx host(s) to it
  xdg.configFile."skhd/skhdrc".text = ''
    hyper - d : yabai -m window --swap east
    hyper - a : yabai -m window --swap west

    hyper - h : yabai -m window --focus west
    hyper - j : yabai -m window --focus south
    hyper - k : yabai -m window --focus north
    hyper - l : yabai -m window --focus east

    meh - f : yabai -m window --toggle zoom-fullscreen

    ctrl - 1 : yabai -m space --focus 1
    ctrl - 2 : yabai -m space --focus 2
    ctrl - 3 : yabai -m space --focus 3
    ctrl - 4 : yabai -m space --focus 4
    ctrl - 5 : yabai -m space --focus 5
    ctrl - 6 : yabai -m space --focus 6
    ctrl - 7 : yabai -m space --focus 7
    ctrl - 8 : yabai -m space --focus 8
    ctrl - 9 : yabai -m space --focus 9

    ctrl - left : yabai -m space --focus prev && yabai -m window --focus first
    ctrl - right : yabai -m space --focus next && yabai -m window --focus first

    meh - b : yabai -m space --balance

    # Move current window to space:
    #  hyper + space_number
    hyper - 1 : yabai -m window --space 1
    hyper - 2 : yabai -m window --space 2
    hyper - 3 : yabai -m window --space 3
    hyper - 4 : yabai -m window --space 4
    hyper - 5 : yabai -m window --space 5
    hyper - 6 : yabai -m window --space 6
    hyper - 7 : yabai -m window --space 7
    hyper - 8 : yabai -m window --space 8
    hyper - 9 : yabai -m window --space 9

    alt - r : yabai -m space --rotate 270
    shift + alt - r : yabai -m space --rotate 90

    meh - a : open /Applications/Alacritty.app

    # Disable built-in shortcuts to hide/minimize applications
    cmd - h : ""
    cmd - m : ""
  '';
}
