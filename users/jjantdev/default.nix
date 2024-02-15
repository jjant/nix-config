{pkgs, ...}: {
  imports = [
    ./tmux
    ./git.nix
    ./starship.nix
    ./fish.nix
    ./alacritty.nix
    # TODO:
    # ./xdg.nix
    # ./zsh.nix
    # ./neovim
    # ./bin
  ];
}
