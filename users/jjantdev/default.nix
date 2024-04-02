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
    nodejs_18

    # Rust watcher/linter
    bacon

    # Pretty markdown in the terminal
    glow
    # Pretty logs
    tailspin

    awscli2

    shellcheck

    # LSPs
    rnix-lsp
    nodePackages.bash-language-server
    nodePackages_latest.typescript-language-server
    taplo

    # Dot, etc.
    graphviz
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
      # TODO: https://github.com/atuinsh/atuin/issues/1724.
      # settings = {
      #   # So that atuin doesn't show the "Update available!" message.
      #   show_help = false;
      # };
      flags = [
        "--disable-up-arrow"
      ];
    };
  };
}
