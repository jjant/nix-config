{ lib, pkgs, ... }: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        echo "Hello from Nix!"
      '';
    };
  };
}
