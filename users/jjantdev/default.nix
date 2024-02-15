{pkgs, ...}: {
  imports = [
    ./tmux
    ./git.nix
    # TODO:
    # ./fish.nix
    # ./xdg.nix
    # ./starship.nix
    # ./zsh.nix
    # ./neovim
    # ./bin
  ];
}
