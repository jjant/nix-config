let
  # Make `<CMD-{number}>` send `<CTRL-B>{number}`
  # We embed the raw STX (0x02) character so TOML serialization preserves it
  prefix = builtins.fromJSON ''"\u0002"'';
  tmuxBindings = [
    {
      key = "1";
      mods = "Command";
      chars = "${prefix}1";
    }
    {
      key = "2";
      mods = "Command";
      chars = "${prefix}2";
    }
    {
      key = "3";
      mods = "Command";
      chars = "${prefix}3";
    }
    {
      key = "4";
      mods = "Command";
      chars = "${prefix}4";
    }
    {
      key = "5";
      mods = "Command";
      chars = "${prefix}5";
    }
    {
      key = "6";
      mods = "Command";
      chars = "${prefix}6";
    }
    {
      key = "7";
      mods = "Command";
      chars = "${prefix}7";
    }
    {
      key = "8";
      mods = "Command";
      chars = "${prefix}8";
    }
    {
      key = "9";
      mods = "Command";
      chars = "${prefix}9";
    }
  ];
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "alacritty";
      };
      window = {
        decorations = "none";
        startup_mode = "Windowed";
        # Fit the Mac's 1512x949-point usable area at 13.5 pt, leaving
        # 28-point side margins and room for the macOS menu bar.
        dimensions = {
          columns = 180;
          lines = 54;
        };
        # Position uses physical pixels (2x Retina), measured from the
        # screen's top-left; start below the 33-point macOS menu bar.
        position = {
          x = 56;
          y = 66;
        };
        padding = {
          x = 8;
          y = 8;
        };
      };
      font = {
        normal = {
          family = "SFMono Nerd Font";
          style = "Light";
        };
        bold = {
          style = "Semibold";
        };
        size = 13.5;
      };
      keyboard = {
        bindings = tmuxBindings;
      };
    };
  };
}
