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

    packages = with pkgs; [ pkgs.exa pkgs.neofetch pkgs.fd ];

  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
