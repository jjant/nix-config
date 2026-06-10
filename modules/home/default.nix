{ pkgs, ... }: {
  imports = [
    ./fish.nix
    ./git.nix
    ./starship.nix
    ./neovim
    ./tmux
    ./bin
  ];

  xdg.enable = true;

  home = {
    sessionVariables = {
      SSH_AUTH_SOCK = "$HOME/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    packages = with pkgs; [
      ripgrep
      fd
      jq
      yq
      tree
      rustup
      tokei
      nodejs_24
      cmake
      duckdb
      hyperfine
      postgresql_17
      railway
      pnpm
      tsx

      # Rust watcher/linter
      bacon

      # Pretty markdown in the terminal
      glow
      # Pretty logs
      tailspin
      # Data utilities
      xan

      awscli2

      shellcheck

      # LSPs
      bash-language-server
      typescript-language-server
      taplo

      # Dot, etc.
      graphviz
    ];

    shellAliases = {
      ls = "eza --binary --header --long --classify";
      la = "ls --all";
      lg = "la --grid";
    };
  };

  programs = {
    bat = {
      enable = true;
      config.theme = "Dracula";
    };
    fzf.enable = true;
    eza.enable = true;

    atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
