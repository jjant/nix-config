{ pkgs, ... }:
let
  dracula = {
    plugin = pkgs.tmuxPlugins.dracula;
    extraConfig = ''
      set -g @dracula-show-powerline true
      set -g @dracula-show-fahrenheit false
      set -g @dracula-show-left-icon session
      set -g @dracula-network-bandwidth false
    '';
  };
in
{
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    clock24 = true;
    keyMode = "vi";
    plugins = [ dracula ];
    historyLimit = 30000;
    escapeTime = 0;
    extraConfig =
      builtins.readFile ./tmux.conf
      + (
        if pkgs.stdenv.isDarwin then
          ''

            # copy-mode `y`: copy to the macOS system clipboard.
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
          ''
        else
          ''

            # copy-mode `y` on the Linux cloud desktops: there is no pbcopy, and
            # copying to the remote's own clipboard is useless over SSH. Emit
            # OSC52 instead (`set-clipboard on`), so tmux hands the selection to
            # the local terminal (alacritty), which writes it to the Mac
            # clipboard through the SSH session.
            set -g set-clipboard on
            bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
          ''
      );
  };
}
