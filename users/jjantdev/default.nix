{pkgs, ...}: {
  imports = [
    ./tmux
    # TODO:
    # ./fish.nix
    # ./xdg.nix
    # ./starship.nix
    # ./zsh.nix
    # ./git.nix
    # ./neovim
    # ./bin
  ];
}
