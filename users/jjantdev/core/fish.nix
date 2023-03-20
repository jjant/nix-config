{ lib, pkgs, config, ... }: {

  home.packages = [ pkgs.zoxide ];

  programs = {
    fish = {
      enable = true;
      loginShellInit = ''
        fish_add_path --append $HOME/.nix-profile/bin
        fish_add_path --append ${config.xdg.configHome}/bin
        fish_add_path --append $HOME/.cargo/bin

        # Export as empty so that the nix-installed `rust-analyzer`
        # doesn't try to use rust stdlib sources from the nix store,
        # as this can causes issues when RA tries to use `cargo metadata`
        # which attempts to write stuff (and nix store files are read-only)
        export RUST_SRC_PATH=
      '';
      interactiveShellInit = ''
        # Disable fish greeting
        set -g fish_greeting

        # TODO: Should I use `function fish_user_key_bindings` for these bindings?

        # Ctrl-s: move cursor to edit command
        bind \cs beginning-of-line forward-bigword

        # Disable default keybindings.
        # See: https://github.com/ellie/atuin/blob/main/docs/key-binding.md#fish
        # This could be simplified after https://github.com/ellie/atuin/issues/660
        # is resolved
        set -gx ATUIN_NOBIND "true"
        atuin init fish | source

        zoxide init fish --cmd j | source

        # bind to ctrl-r in normal and insert mode, add any other bindings you want here too
        bind \cr _atuin_search
        bind -M insert \cr _atuin_search

        bind \cf tmux-sessionizer

        abbr --add gcm --set-cursor="%" "git commit -m \"%\""
      '';

      shellAbbrs = {
        # Maybe move these to the `git.nix` file?
        ga = "git add";
        gb = "git branch";
        gst = "git status";
        gco = "git checkout";
        gcv = "git commit";
        gd = "git diff";
        gds = "git diff --staged";
        gp = "git push";
        gpf = "git push --force-with-lease";
        gl = "git pull";
        gam = "git commit --amend --no-edit";
        game = "git commit --amend";
        glog = "git log --oneline --decorate --reverse -10";
        glg = "git log --decorate --pretty=format:'%C(auto)%h %C(green)(%as)%C(reset)%C(blue) %<(20,trunc) %an%C(reset) %s%C(auto)%d'";
        gm = "git merge";

        vi = "nvim";
        vim = "nvim";

        bz = "brazil";
        bw = "brazil workspace";
        bb = "brazil-build";
        bbb = "brazil-build build";

        edabb = "eda build brazil-build build";
        tx = "toolbox";
        wp = "cd ~/workplace";
        bp = "brazil-workspace-from-package";
        sms = "go-to-smithy-rs-latest-tmp";
        smt = "smithy-codegen-targets server";
        smc = "smithy-codegen-targets client";

        mw = "mwinit";
      };

      functions = {
        jr = {
          description = "`cd` to this git repo's root";
          body = ''
            set repoRoot $(git rev-parse --show-toplevel 2> /dev/null)

            if test $status -ne 0
              echo "Not a git repository"
              return 1
            end
            cd $repoRoot
          '';
        };
        brazil-workspace-from-package = {
          description = "Create a workspace with a single package.";
          body = ''
            set package $argv[1]

            if test -z "$package"
              echo "Package name required"
              return 1
            end

            brazil ws create --name $package
            and cd $package
            and brazil ws use -p $package
          '';
        };
        go-to-smithy-rs-latest-tmp = {
          description = "Navigate to the latest code generated smithy test files";
          body = ''
            set baseDir "$HOME/.local/share/smithy-test-workspace"
            set rustProjectDir $(exa --sort modified $baseDir -D | tr " " "\n" | tail -n1)

            if test -z "$rustProjectDir"
              echo "No code generated directory found"
              return 1
            end

            cd "$baseDir/$rustProjectDir"
          '';
        };
        smithy-codegen-targets = {
          description = "Navigate to smithy-rs's codegen-{server,client}-test targets";
          body = ''
            set clientOrServer "$argv[1]"

            if test "$clientOrServer" = "server" -o "$clientOrServer" = "client"
            else
              echo "Target must be either `server` or `client`, but it was `$clientOrServer`"
              return 1
            end

            set baseDirName "codegen-$clientOrServer-test"
            set codegenTargetsDir "$baseDirName/build/smithyprojections/$baseDirName/"

            jr

            if not test -d $codegenTargetsDir
              echo "Not in the smithy-rs repo"
              return 1
            end

            set targets $(exa -D $codegenTargetsDir)
            set pickedTarget $(echo $targets | tr " " "\n" | fzf)

            if test -z "$pickedTarget"
              echo "No target selected"
              return 2
            end

            set srcDir "rust-$clientOrServer-codegen"
            cd "$codegenTargetsDir/$pickedTarget/$srcDir"
          '';
        };
        today = {
          description = ''
            Create a file with today's date as a name.
            Use the first argument to
          '';
          body = ''
            set default_extension "md"
            set base_name $(date "+%Y-%m-%d")
            set extension $argv[1]

            if test -z "$extension"
              set extension "$default_extension"
            end

            set file_name "$base_name.$extension"

            if test -e $file_name
              echo "File `$file_name` already exists, skipping creation"
              return 1
            end

            touch $file_name
            echo "Created file: $file_name"
          '';
        };
      };
    };
  };
}
