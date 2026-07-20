{ pkgs, lib, ... }: {
  imports = [
    ./fish.nix
    ./zsh.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
    ./neovim
    ./tmux
    ./bin
  ];

  xdg.enable = true;

  # On the Linux cloud desktops, register docker-compose as a Docker CLI plugin
  # so `docker compose` (subcommand) works, not just the standalone
  # `docker-compose` binary.
  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    "docker/cli-plugins/docker-compose".source =
      "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";

    # Nix client config (macOS gets all of this system-wide via nix-darwin's
    # nix.settings in modules/darwin instead). The substituter/key are only
    # honored because /etc/nix/nix.conf marks us a trusted user — a one-time
    # step in the README's first-time setup.
    "nix/nix.conf".text = ''
      experimental-features = nix-command flakes
      extra-substituters = https://jjant-nix.cachix.org
      extra-trusted-public-keys = jjant-nix.cachix.org-1:g3Dup2VOxdS2kNwIxoQ7JVl0W/mhrTHv7jvFHOYAFd4=
    '';
  };

  home = {
    # Point JAVA_HOME at the jdk25 package. `.home` is correct on both
    # platforms: on macOS (Zulu) it's the store root; on Linux (OpenJDK)
    # it resolves to `$out/lib/openjdk`. Nix injects the (hashed) store
    # path and refreshes it on every rebuild, so it's never hardcoded.
    sessionVariables = {
      JAVA_HOME = pkgs.jdk25.home;
    };

    file = {
      # ~/.hushlogin: sshd honors it on the Linux cloud desktops (suppresses the
      # Amazon Linux MOTD banner + the "Last login" line shown over SSH), and
      # /usr/bin/login honors it on macOS (silences Terminal's
      # "Last login: … on ttysNNN"). Editing /etc/motd wouldn't stick — the
      # dev-desktop tooling regenerates it.
      ".hushlogin".text = "";

      # Stable, hash-free JAVA_HOME paths, one per JDK major version. Tools that
      # persist an absolute JDK path in their own config can point at a fixed
      # ~/.jdks/<major> location instead of a /nix/store path whose hash changes
      # on every upgrade. home-manager repoints the symlink target on each
      # rebuild; the ~/.jdks/<major> path itself stays constant.
      ".jdks/8".source = pkgs.jdk8.home;
      ".jdks/11".source = pkgs.jdk11.home;
      ".jdks/17".source = pkgs.jdk17.home;
      ".jdks/21".source = pkgs.jdk21.home;
      ".jdks/25".source = pkgs.jdk25.home;
    };

    packages =
      with pkgs;
      [
        ripgrep
        fd
        jq
        yq
        tree
        dust # intuitive `du`: disk usage per directory
        btop # resource monitor: prettier, more interactive `top`
        rustup
        tokei
        nodejs_24
        ruby
        jdk25 # Java: latest LTS (Azul Zulu build from nixpkgs)
        uv
        mosquitto
        cmake
        duckdb
        hyperfine
        postgresql_17
        railway
        pnpm
        tsx
        mprocs

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
        cargo-rdme
        cargo-tarpaulin # redundant with cargo-llvm-cov; candidate to drop
        cargo-zigbuild
        grcov
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
      ]
      # Docker tooling only on the Linux cloud desktops (mac uses Docker Desktop).
      ++ lib.optionals pkgs.stdenv.isLinux [
        docker
        docker-compose
      ];

    shellAliases = {
      ls = "eza --binary --header --long --classify=auto";
      la = "ls --all";
      lg = "la --grid";
    };
  };

  programs = {
    # Installs the `home-manager` CLI itself into the profile. Without this,
    # only the generated activation package is built; the switcher command
    # is never placed on PATH, so bare `home-manager <subcommand>` (e.g.
    # `home-manager news`) fails until you fall back to
    # `nix run home-manager -- <subcommand>`. Not needed on macOS: darwin
    # config there goes through nix-darwin's home-manager module instead
    # (see hosts/mac-m1.nix).
    home-manager.enable = pkgs.stdenv.isLinux;

    bat = {
      enable = true;
      config.theme = "Dracula";
    };
    fzf = {
      enable = true;
      # Atuin owns Ctrl-R (bound in fish.nix); disable fzf's history widget
      # so the two don't both bind Ctrl-R.
      historyWidget.command = "";
    };
    eza.enable = true;

    # Delta (and man, etc.) page through less, where bare `s` prompts to save
    # the piped input to a file ("log file:") — too easy to hit accidentally.
    # Disable it and keep the feature on a deliberate ESC-s instead. Enabling
    # the module also installs a modern less: macOS ships 581, which predates
    # support for reading this lesskey source file (added in less 590).
    less = {
      enable = true;
      config = ''
        #command
        s    noaction
        # Same action as the stock `s` binding (`toggle-option o`). The long
        # spelling (`toggle-option -log-file`) would leave less's option
        # prompt waiting for an extra Enter before asking for the file name.
        \es  toggle-option o
      '';
    };

    atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
    };

    # Owns `j` (was hand-rolled `zoxide init fish --cmd j` in fish.nix); the
    # module generates the init with zoxide pinned to its store path.
    zoxide = {
      enable = true;
      options = [
        "--cmd"
        "j"
      ];
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
