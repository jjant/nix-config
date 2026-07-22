{ pkgs, lib, ... }:
let

  amazonGitConfigOverride = {
    user = {
      name = "jjantdev";
      email = "jjantdev@amazon.co.uk";
    };
    init.defaultBranch = "mainline";
  };

in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      syntax-theme = "Dracula";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    hooks.pre-commit = pkgs.writeShellScript "pre-commit-ripsecrets" ''
      ${pkgs.ripsecrets}/bin/ripsecrets --strict-ignore
    '';

    # Use the Amazon identity inside Brazil workspaces. The workspace root
    # differs by platform: /Volumes/workplace on macOS, ~/workplace on the
    # Linux cloud desktops.
    includes = [
      {
        condition = "gitdir:/Volumes/workplace/";
        contents = amazonGitConfigOverride;
      }
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      {
        condition = "gitdir:~/workplace/";
        contents = amazonGitConfigOverride;
      }
    ];

    settings = {
      color.ui = true;
      init.defaultBranch = "main";
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
