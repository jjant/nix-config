{ lib, pkgs, ... }: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Disable fish greeting
        set -g fish_greeting

        # Ctrl-s: move cursor to edit command
        bind \cs beginning-of-line forward-bigword

        # Disable default keybindings.
        # See: https://github.com/ellie/atuin/blob/main/docs/key-binding.md#fish
        # This could be simplified after https://github.com/ellie/atuin/issues/660
        # is resolved
        set -gx ATUIN_NOBIND "true"
        atuin init fish | source

        # bind to ctrl-r in normal and insert mode, add any other bindings you want here too
        bind \cr _atuin_search
        bind -M insert \cr _atuin_search
      '';

      shellAbbrs = {
        ga = "git add";
        gst = "git status";
        gco = "git checkout";
        gcm = "git commit -m";
        gcv = "git commit";
        gd = "git diff";
        gds = "git diff --staged";
        gp = "git push";
        gl = "git pull";

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
