{pkgs, ...}: {
  imports = [
    ./tmux
    ./git.nix
    ./starship.nix
    # TODO:
    # ./fish.nix
    # ./xdg.nix
    # ./zsh.nix
    # ./neovim
    # ./bin
  ];
}
