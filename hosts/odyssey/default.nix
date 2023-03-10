{ lib, pkgs, ... }: {
  imports = [ ../../users/jjantdev/core ];

  home = {
    # uid = 504;
    packages = [ pkgs.btop ];
  };

  programs = {
    home-manager.enable = true;
    fish.shellInit = ''
      fish_add_path --append --path "$HOME/.toolbox/bin"

      set --erase LS_COLORS
    '';
    git = {
      userEmail = lib.mkForce "jjantdev@amazon.co.uk";
      # ^ mkForce gives priority to this value in case of multiple definitions
      # or at least, that's my understanding.
    };
    zsh = {
      initExtra = ''
        source $HOME/.nix-profile/etc/profile.d/nix.sh
        export PATH=$HOME/.nix-profile/bin:$PATH

        if [ -z "$ZSH_AUTO_RAN_FISH" ]; then
            export ZSH_AUTO_RAN_FISH=YES
            export SHELL="$(realpath "$(which fish)")"
            exec fish --login
        else
          export PATH="$PATH:$HOME/.toolbox/bin"
        fi
      '';
    };
  };
}
