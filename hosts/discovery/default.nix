{ lib, pkgs, ... }: {
  imports = [ ../../users/jjantdev/core ./skhd.nix ./yabai ];

  home = { packages = [ ]; };

  programs = {
    home-manager.enable = true;
    fish.shellInit = ''
      fish_add_path --append --path "$HOME/.toolbox/bin"
    '';
    git = {
      userEmail = lib.mkForce "julianantonielli@gmail.com";
      # ^ mkForce gives priority to this value in case of multiple definitions
      # or at least, that's my understanding.
    };
  };
}
