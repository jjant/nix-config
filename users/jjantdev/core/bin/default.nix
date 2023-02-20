{ pkgs, ... }: {
  xdg.configFile."bin/tmux-sessionizer".source = ./tmux-sessionizer;
  xdg.configFile."bin/pnew".source = ./pnew;
}
