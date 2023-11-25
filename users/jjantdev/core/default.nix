{ pkgs, ... }: {

  imports = [
    ./fish.nix
    ./xdg.nix
    ./starship.nix
    ./zsh.nix
    ./git.nix
    ./neovim
    ./tmux
    ./bin
  ];

  home = {
    username = "jjantdev";

    stateVersion = "22.11";

    packages = with pkgs; [
      btop

      nodejs
      jq

      nodePackages.serve
      eza
      neofetch
      fd
      ripgrep
      rustup
      tokei
      pre-commit
      git-secrets
      hyperfine

      awscli2

      shellcheck

      # LSPs
      sumneko-lua-language-server
      rnix-lsp
      # rust-analyzer
      nodePackages.bash-language-server
      nodePackages_latest.typescript-language-server
      taplo

      graphviz # dot, neato, etc
    ];

    shellAliases = {
      ls = "eza --binary --header --long --classify";
      la = "ls --all";
      lg = "la --grid";
    };
  };

  programs = {
    bat.enable = true;
    atuin.enable = true;
    fzf.enable = true;
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
