{ lib, pkgs, ... }: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Disable fish greeting
        set -g fish_greeting
      '';

      shellAbbrs = {
        gst = "git status";

        bz = "brazil";
        bw = "brazil workspace";
        bb = "brazil-build";
        tx = "toolbox";
        wp = "cd ~/workplace";
      };
    };
  };
}
