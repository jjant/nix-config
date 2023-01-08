{ lib, pkgs, ... }: {
  programs.git = {
    enable = true;

    userName = "Julian Antonielli";
    userEmail = "julianantonielli@gmail.com";

    extraConfig = {
      color.ui = true;
      init.defaultBranch = "master";
      pull.rebase = false;
      push = {
        default = "current";
        autoSetupRemote = true;
      };
    };
  };

  home.shellAliases = {
    ga = "git add";
    gco = "git checkout";
    gcm = "git commit -m";
  };
}
