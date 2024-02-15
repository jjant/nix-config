{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, config, lib, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [
          pkgs.vim
          pkgs.neovim
        ];
        environment.systemPath = [
          "/opt/homebrew/bin"
        ];
        environment.shells = [
          pkgs.zsh
          pkgs.fish
        ];

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina

        programs.fish.enable = true;
        # programs.fish.loginShellInit = ''
        #   fish_add_path --append "$HOME/.nix-profile/bin"
        #   fish_add_path --append "/etc/profiles/per-user/$USER/bin"
        #   fish_add_path --append "/nix/var/nix/profiles/default/bin"
        #   fish_add_path --append "/run/current-system/sw/bin"
        # '';

        # See: https://github.com/LnL7/nix-darwin/issues/122
        programs.fish.loginShellInit =
          let
            # This naive quoting is good enough in this case. There shouldn't be any
            # double quotes in the input string, and it needs to be double quoted in case
            # it contains a space (which is unlikely!)
            dquote = str: "\"" + str + "\"";

            makeBinPathList = map (path: path + "/bin");
          in
          ''
            fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList config.environment.profiles)}
            set fish_user_paths $fish_user_paths

            # Amazon stuff
            fish_add_path --append "$HOME/.toolbox/bin"

            # Personal scripts
            # TODO: set up XDG variables with home-manager.
            #  then replace $HOME/.config with config.xdg.configHome (nix value).
            fish_add_path --append "$HOME/.config/bin"

            # Rust binaries
            fish_add_path --append "$HOME/.cargo/bin"
          '';
        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # TODO: For some reason nix thinks this is an x86_64 machine.
        # nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.hostPlatform = "x86_64-darwin";

        # My configs
        system.defaults.dock.mru-spaces = false;
        system.defaults.universalaccess.mouseDriverCursorSize = 1.75;
        system.defaults.trackpad.TrackpadRightClick = true;
        system.defaults.dock.autohide = true;
        # Make Finder killable
        system.defaults.finder.QuitMenuItem = true;

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;

        services.skhd = {
          enable = true;
          skhdConfig = # TODO: Add skhd config.
            ''
            '';
        };

        homebrew = {
          enable = true;
          brewPrefix = "/opt/homebrew/bin/";

          taps = [
            # See: https://github.com/epk/SF-Mono-Nerd-Font
            "epk/epk"
          ];

          casks = [
            { name = "lunar"; greedy = true; }
            { name = "raycast"; greedy = true; }
            { name = "1password"; greedy = true; }
            { name = "1password-cli"; greedy = true; }
            { name = "signal"; greedy = true; }
            # Installs "SFMono Nerd Font" font
            { name = "font-sf-mono-nerd-font"; greedy = true; }
          ];
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jjantdev = {
                home.stateVersion = "23.11";
                home.homeDirectory = nixpkgs.lib.mkForce "/Users/jjantdev";

                programs.alacritty = {
                  enable = true;
                };

                programs.eza.enable = true;

                programs.tmux.enable = true;

                programs.atuin = {
                  enable = true;
                  flags = [
                    "--disable-up-arrow"
                  ];
                };

                imports = [
                  ({ pkgs, ... }: {
                    home.packages = [
                      pkgs.htop
                    ];
                  })
                ];
              };
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."simple".pkgs;
    };
}

