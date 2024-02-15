{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          [
            pkgs.vim
          ];


        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina

        programs.fish.enable = true;
        programs.fish.loginShellInit = ''
          fish_add_path --append "$HOME/.nix-profile/bin"
          fish_add_path --append "/etc/profiles/per-user/$USER/bin"
          fish_add_path --append "/nix/var/nix/profiles/default/bin"

          # Rust binaries
          fish_add_path --append "$HOME/.cargo/bin"

          # Personal scripts
          # TODO: set up XDG variables with home-manager.
          #  then replace $HOME/.config with config.xdg.configHome (nix value).
          fish_add_path --append "$HOME/.config/bin"

          # Amazon stuff
          fish_add_path --append "$HOME/.toolbox/bin"
        '';

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
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
          skhdConfig = # Example to check it works
            ''
              cmd - return : osascript -e 'display notification "Lorem ipsum dolor sit amet" with title "Title"'
            '';
        };

        homebrew = {
          enable = true;

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
        modules = [ configuration ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."simple".pkgs;
    };
}

