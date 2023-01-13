{ pkgs, ... }: {
  xdg.configFile."bin/tmux-sessionizer".source = ./tmux-sessionizer;
}
