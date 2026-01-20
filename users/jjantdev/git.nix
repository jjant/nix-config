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

    # Github email
    # TODO: Verify what the key in this map should be.
    settings.userName = {
      jjant = "Julian Antonielli";
    };
    # TODO: Verify the value of this option.
    settings.userEmail = {
      "jjant" = "julianantonielli@gmail.com";
    };

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
