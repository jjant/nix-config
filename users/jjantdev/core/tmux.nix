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
    historyLimit = 30000;
    escapeTime = 0;
    extraConfig = ''
      # Start window and pane indices at 1
      set -g base-index 1
      set -g pane-base-index 1

      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Alt+hjkl to move between panes (macOS)
      bind-key -n ˙ select-pane -L
      bind-key -n ∆ select-pane -D
      bind-key -n ˚ select-pane -U
      bind-key -n ¬ select-pane -R

      # Vim keys: use `v` to enter visual mode, `y` to yank
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
    '';
  };
}
