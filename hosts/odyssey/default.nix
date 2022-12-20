{ lib, pkgs, ... }: {
  imports = [ ../../users/jjantdev/core ];

  home = {
    # uid = 504;
    packages = [ pkgs.btop pkgs.rustup ];
  };

  programs = {
    home-manager.enable = true;
    fish.shellInit = ''
      fish_add_path --apend --path "$HOME/.toolbox/bin"
    '';
    git = {
      userEmail = lib.mkForce "jjantdev@amazon.co.uk";
      # ^ mkForce gives priority to this value in case of multiple definitions
      # or at least, that's my understanding.
    };
  };
}
