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

  home.sessionVariables = {
    # TODO: Move somewhere more appropriate.
    # TODO: How does Bernardo put this in a nicer path?
    # https://github.com/lovesegfault/nix-config/blob/d5f1700b8463d4250e8fbe697c74faa50325d4f4/users/bemeurer/trusted/graphical.nix#L8
    SSH_AUTH_SOCK = "$HOME/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

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
