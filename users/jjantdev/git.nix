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
    lfs.enable = true;



    includes = [
      {
        condition = "gitdir:/Volumes/workplace/";
        contents = amazonGitConfigOverride;
      }
    ];

    settings = {
      color.ui = true;
      init.defaultBranch = "master";
      pull.rebase = false;
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      user = {
        name = "Julian Antonielli";
        # Github email
        email = "julianantonielli@gmail.com";
      };
      core.excludesFile = "${pkgs.writeTextFile {
        name = "globalGitExcludeFile";
        text = ''
          # IntelliJ files
          *.iml
        '';
      }}";
    };
  };
}
