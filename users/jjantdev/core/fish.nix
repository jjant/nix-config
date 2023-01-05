{ lib, pkgs, ... }: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Disable fish greeting
        set -g fish_greeting
      '';

      shellAbbrs = {
        ga = "git add";
        gst = "git status";
        gco = "git checkout";
        gcm = "git chekout -m";
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
