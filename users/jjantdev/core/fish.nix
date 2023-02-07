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
        tx = "toolbox";
        wp = "cd ~/workplace";
      };
    };
  };
}
