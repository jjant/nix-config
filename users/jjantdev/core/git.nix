{ lib, pkgs, ... }: {
  programs.git = {
    enable = true;

    userName = "Julian Antonielli";
    userEmail = "julianantonielli@gmail.com";
  };

  home.shellAliases = {
    ga = "git add";
    gco = "git checkout";
    gcm = "git commit -m";
  };
}
