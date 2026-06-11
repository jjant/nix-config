{ pkgs, ... }:
let

  amazonGitConfigOverride = {
    user = {
      name = "jjantdev";
      email = "jjantdev@amazon.co.uk";
    };
  };

in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = { navigate = true; syntax-theme = "Dracula"; };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    hooks.pre-commit = pkgs.writeShellScript "pre-commit-ripsecrets" ''
      ${pkgs.ripsecrets}/bin/ripsecrets --strict-ignore
    '';



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
