{ pkgs, ... }: {
  imports = [
    ./tmux
    ./git.nix
    ./starship.nix
    ./fish.nix
    ./alacritty.nix
    ./bin
    ./neovim
    # TODO:
    # ./xdg.nix
    # ./zsh.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    fd
    neofetch
    jq
    tree
    rustup
    tokei

    # LSPs
    shellcheck
    rnix-lsp
  ];

  home.shellAliases = {
    ls = "eza --binary --header --long --classify";
    la = "ls --all";
    lg = "la --grid";
  };

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
