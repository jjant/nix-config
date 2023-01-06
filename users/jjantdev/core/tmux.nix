{ pkgs, ... }:
let
  dracula = {
    plugin = pkgs.tmuxPlugins.dracula;
    extraConfig = ''
      set -g @dracula-show-powerline true
      set -g @dracula-show-fahrenheit false
      set -g @dracula-show-left-icon session
      set -g @dracula-military-time true
    '';
  };
in {
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    clock24 = true;
    keyMode = "vi";
    plugins = [ dracula ];
    extraConfig = ''
      # Start window and pane indices at 1
      set -g base-index 1
      set -g pane-base-index 1

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
