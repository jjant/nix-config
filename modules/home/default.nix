{ pkgs, ... }: {
  imports = [
    ./fish.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
    ./neovim
    ./tmux
    ./bin
  ];

  xdg.enable = true;

  home = {
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

      # Rust dev tooling (migrated from `cargo install`)
      cargo-audit
      cargo-binstall
      cargo-bloat
      cargo-cache
      cargo-deny
      cargo-expand
      cargo-fuzz
      cargo-insta
      cargo-llvm-cov
      cargo-mutants
      cargo-nextest
      cargo-outdated
      cargo-tarpaulin # redundant with cargo-llvm-cov; candidate to drop
      cargo-zigbuild
      inferno # flamegraph backend; rarely used standalone
      wasm-pack

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
