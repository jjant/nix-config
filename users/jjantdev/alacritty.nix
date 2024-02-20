let
  # Make `<CMD-{number}>` send `<CTRL-B>{number}`
  tmuxBindings = [
    { key = "1"; mods = "Command"; chars = "\\u00021"; }
    { key = "2"; mods = "Command"; chars = "\\u00022"; }
    { key = "3"; mods = "Command"; chars = "\\u00023"; }
    { key = "4"; mods = "Command"; chars = "\\u00024"; }
    { key = "5"; mods = "Command"; chars = "\\u00025"; }
    { key = "6"; mods = "Command"; chars = "\\u00026"; }
    { key = "7"; mods = "Command"; chars = "\\u00027"; }
    { key = "8"; mods = "Command"; chars = "\\u00028"; }
    { key = "9"; mods = "Command"; chars = "\\u00029"; }
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
      };
      font = {
        normal = {
          family = "SFMono Nerd Font";
          style = "Light";
        };
        bold = {
          style = "Semibold";
        };
        size = 15;
      };
      keyboard = {
        bindings = tmuxBindings;
      };
    };
  };
}
