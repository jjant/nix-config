{pkgs, ...}: {
  imports = [
    ./tmux
    ./git.nix
    ./starship.nix
    ./fish.nix
    ./alacritty.nix
    ./bin
    # TODO:
    # ./xdg.nix
    # ./zsh.nix
    # ./neovim
  ];

  programs = {
    bat.enable = true;
    fzf.enable = true;
    eza.enable = true;

    atuin = {
      enable = true;
      flags = [
        "--disable-up-arrow"
      ];
    };
  };
}
