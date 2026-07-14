{
  description = "jjant's nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NB: no `follows` — nix-homebrew declares no nixpkgs input.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Full VS Code marketplace (+ Open VSX) as a nixpkgs overlay:
    # pkgs.vscode-marketplace.<publisher>.<name>.
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Trampolines so nix-store GUI apps show up in Spotlight/Dock.
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    "vim-plugin:LunarVim/darkplus.nvim" = {
      url = "github:LunarVim/darkplus.nvim";
      flake = false;
    };

    "vim-plugin:L3MON4D3/LuaSnip" = {
      url = "github:L3MON4D3/LuaSnip";
      flake = false;
    };

    "vim-plugin:rafamadriz/friendly-snippets" = {
      url = "github:rafamadriz/friendly-snippets";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # Platforms this flake's hosts run on.
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      vimPlugins = lib.mapAttrs' (name: value: {
        name = lib.removePrefix "vim-plugin:" name;
        inherit value;
      }) (lib.filterAttrs (name: _: lib.hasPrefix "vim-plugin:" name) inputs);

      # A Linux cloud desktop. The hosts only differ in platform and prompt
      # tag; everything else lives in ../modules/home.
      mkHome =
        alias: system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit vimPlugins; };
          modules = [
            ./modules/home
            {
              home = {
                username = "jjantdev";
                homeDirectory = "/home/jjantdev";
                stateVersion = "23.11";
                sessionVariables.STARSHIP_HOST_ALIAS = alias;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations.mac-m1 = import ./hosts/mac-m1.nix {
        inherit
          self
          nixpkgs
          home-manager
          vimPlugins
          nix-darwin
          nix-homebrew
          ;
        inherit (inputs) nix-vscode-extensions mac-app-util;
      };

      homeConfigurations = lib.mapAttrs mkHome {
        al2-x86_64 = "x86_64-linux";
        al2-aarch64 = "aarch64-linux";
        al2023-x86_64 = "x86_64-linux";
      };

      darwinPackages = self.darwinConfigurations.mac-m1.pkgs;

      # `nix flake check` builds every host that can build on the current
      # platform (same attrs CI builds), so it works as a single local gate.
      checks = {
        x86_64-linux = {
          al2-x86_64 = self.homeConfigurations.al2-x86_64.activationPackage;
          al2023-x86_64 = self.homeConfigurations.al2023-x86_64.activationPackage;
        };
        aarch64-linux = {
          al2-aarch64 = self.homeConfigurations.al2-aarch64.activationPackage;
        };
        aarch64-darwin = {
          mac-m1 = self.darwinConfigurations.mac-m1.system;
        };
      };

      # `nix fmt` — official Nix formatting (RFC 166) via the treefmt wrapper,
      # which handles tree-walking (plain nixfmt deprecated directory args).
      formatter = lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # nix run .#activate — auto-detects host type and applies config
      apps = lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          activate = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "activate" ''
                set -e

                # Bootstrap: make flakes available to the *nested* `nix run` calls
                # below (nix-darwin / home-manager) on a machine that has no
                # persistent nix.conf yet. NIX_CONFIG is inherited by child nix
                # processes; a `--extra-experimental-features` CLI flag is not.
                # `extra-` so we don't clobber features enabled elsewhere.
                export NIX_CONFIG="extra-experimental-features = nix-command flakes"

                if [ "$(uname)" = "Darwin" ]; then
                  if command -v darwin-rebuild &>/dev/null; then
                    sudo darwin-rebuild switch --flake .#mac-m1 "$@"
                  else
                    nix run nix-darwin -- switch --flake .#mac-m1 "$@"
                  fi
                elif grep -q "2023" /etc/os-release 2>/dev/null; then
                  if command -v home-manager &>/dev/null; then
                    home-manager switch --flake .#al2023-"$(uname -m)" "$@"
                  else
                    nix run home-manager -- switch --flake .#al2023-"$(uname -m)" "$@"
                  fi
                else
                  if command -v home-manager &>/dev/null; then
                    home-manager switch --flake .#al2-"$(uname -m)" "$@"
                  else
                    nix run home-manager -- switch --flake .#al2-"$(uname -m)" "$@"
                  fi
                fi
              ''
            );
          };
          update = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "update" ''
                nix flake update
              ''
            );
          };
        }
      );
    };
}
