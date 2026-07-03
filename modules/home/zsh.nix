{ pkgs, lib, config, ... }: {
  # Only manage zsh on the Linux cloud desktops.
  #
  # On macOS the login shell is already fish (via `chsh`) and `~/.zshrc` is
  # managed by hand, so we leave it alone there rather than have home-manager
  # take ownership of it.
  #
  # On the cloud desktops we're not allowed to `chsh`, and making a non-POSIX
  # shell the login shell would break scp/rsync/non-interactive ssh. So we keep
  # zsh as the login shell and hand *interactive* shells off to fish instead.
  programs.zsh = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    # Lock in the current "dotfiles live directly in $HOME" behavior. Without
    # this, home-manager warns that the default will switch to an
    # XDG-config-based location in a future release; we're not opting into
    # that layout right now, just silencing the warning.
    dotDir = config.home.homeDirectory;
    initContent = ''
      # Ensure Builder Toolbox is on PATH before we hand off to fish, so the
      # exec'd fish inherits it.
      if [ -d "$HOME/.toolbox/bin" ]; then
        export PATH="$HOME/.toolbox/bin:$PATH"
      fi

      # Hand interactive shells to fish. Non-interactive shells (scp, rsync,
      # `ssh host cmd`) never source this file, so they stay POSIX zsh.
      #
      # ZSH_AUTO_RAN_FISH does double duty:
      #   1. prevents an exec loop, and
      #   2. is inherited by fish, so running `zsh` from within fish drops you
      #      into a real zsh instead of bouncing straight back to fish.
      if [[ -z "$ZSH_AUTO_RAN_FISH" ]] && [[ -o interactive ]] && [[ -x "$HOME/.nix-profile/bin/fish" ]]; then
        export ZSH_AUTO_RAN_FISH=YES
        export SHELL="$HOME/.nix-profile/bin/fish"
        exec "$HOME/.nix-profile/bin/fish" --login
      fi
    '';
  };
}
