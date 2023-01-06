{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    clock24 = true;
    keyMode = "vi";
    plugins = [ pkgs.tmuxPlugins.dracula ];
    extraConfig = ''
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Alt+hjkl to move between panes (macOS)
      bind -n ˙ select-pane -L
      bind -n ∆ select-pane -D
      bind -n ˚ select-pane -U
      bind -n ¬ select-pane -R

      # Dracula theme configuration
      set -g @dracula-show-powerline true
      set -g @dracula-show-fahrenheit false
      set -g @dracula-show-left-icon session
      set -g @dracula-military-time true
    '';
  };
}
