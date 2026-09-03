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
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      {
        condition = "gitdir:~/workplace/";
        contents = amazonGitConfigOverride;
      }
    ];

    settings = {
      color.ui = true;
      init.defaultBranch = "main";

      # Refuse a `git pull` that can't fast-forward, instead of quietly
      # spinning a merge commit. `pull.rebase = false` used to live here, which
      # is precisely what opted us into the silent merge: git's own default for
      # a divergent pull is already --ff-only, and it only merges once you tell
      # it to. So this removes that opt-in rather than adding a new rule. On a
      # diverged branch the pull now aborts and the reconciliation is a
      # deliberate `git pull --rebase` (or an explicit merge).
      pull.ff = "only";

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      rerere = {
        # Record how conflicts were resolved and replay the same resolution the
        # next time the identical conflict hunk shows up — the payoff is
        # re-resolving the same conflict on every retry of a rebase.
        #
        # Not on by default: git only auto-enables rerere if $GIT_DIR/rr-cache
        # already exists, and nothing creates that directory until rerere has
        # run at least once. So it stays off forever unless set here.
        enabled = true;
        # Stage the replayed resolution instead of leaving the path conflicted.
        # Without this rerere fixes up the working tree but the file stays
        # unmerged, so it reads as "rerere did nothing" and you re-resolve by
        # hand anyway.
        autoUpdate = true;
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
