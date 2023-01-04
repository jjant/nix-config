{ pkgs, ... }: {

  imports = [
    ./fish.nix
    ./xdg.nix
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
    ./git.nix
    ./neovim
  ];

  home = {
    username = "jjantdev";

    stateVersion = "22.11";

    packages = with pkgs; [ exa neofetch fd ripgrep ];

    shellAliases = {
      ls = "exa --binary --header --long --classify";
      la = "ls --all";
      lg = "la --grid";
    };
  };

  programs = {
    bat.enable = true;
    atuin = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
