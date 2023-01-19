{ lib, pkgs, config, ... }: {

  home.packages = [ pkgs.zoxide ];

  programs = {
    fish = {
      enable = true;
      loginShellInit = ''
        fish_add_path --append $HOME/.nix-profile/bin
        fish_add_path --append ${config.xdg.configHome}/bin
        fish_add_path --append $HOME/.cargo/bin
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
        gst = "git status";
        gco = "git checkout";
        gcv = "git commit";
        gd = "git diff";
        gds = "git diff --staged";
        gp = "git push";
        gpf = "git push --force-with-lease";
        gl = "git pull";
        gam = "git commit --amend";
        glog = "git log --oneline --decorate --reverse -10";
        gm = "git merge";

        vi = "nvim";
        vim = "nvim";

        bz = "brazil";
        bw = "brazil workspace";
        bb = "brazil-build";
        tx = "toolbox";
        wp = "cd ~/workplace";
      };
      functions = {
        jr = {
          description = "`cd` to this git repo's root";
          body = "cd $(git rev-parse --show-toplevel)";
        };
      };
    };
  };
}
