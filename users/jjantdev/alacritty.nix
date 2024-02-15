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
    };
  };
}
