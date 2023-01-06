{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    clock24 = true;
    keyMode = "vi";
    extraConfig = ''
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Alt+hjkl to move between panes (macOS)
      bind -n ˙ select-pane -L
      bind -n ∆ select-pane -D
      bind -n ˚ select-pane -U
      bind -n ¬ select-pane -R
    '';
  };
}
