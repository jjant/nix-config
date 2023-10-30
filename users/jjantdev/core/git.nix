{ lib, pkgs, ... }:
let

  amazonGitConfigOverride = {
    user = {
      name = "jjantdev";
      email = "jjantdev@amazon.co.uk";
    };
  };

in
{
  programs.git = {
    enable = true;

    userName = "Julian Antonielli";
    userEmail = "julianantonielli@gmail.com";

    includes = [
      {
        condition = "gitdir:/Volumes/workplace/";
        contents = amazonGitConfigOverride;
      }
    ];

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
}
