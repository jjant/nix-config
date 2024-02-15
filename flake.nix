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

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
  }: let
    hosts = import ./hosts;
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config = {
          allowUnfree = true;
        };
      };
      modules = [
        {
          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;
        }
        ./darwin
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
              programs.tmux.extraConfig = ''
                set-option -g default-terminal "alacritty"
                set-option -ga terminal-overrides ",alacritty:RGB"
              '';

              programs.atuin = {
                enable = true;
                flags = [
                  "--disable-up-arrow"
                ];
              };

              imports = [
                ./users/jjantdev
                ({pkgs, ...}: {
                  home.packages = [
                    pkgs.htop
                    pkgs.jetbrains.idea-ultimate
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
