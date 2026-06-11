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
    inputs @ { self
    , nix-darwin
    , nixpkgs
    , home-manager
    , ...
    }:
    let
      inherit (nixpkgs) lib;

      vimPlugins =
        lib.mapAttrs'
          (name: value: {
            name = lib.removePrefix "vim-plugin:" name;
            inherit value;
          })
          (lib.filterAttrs (name: _: lib.hasPrefix "vim-plugin:" name) inputs);

      commonArgs = { inherit self nixpkgs home-manager vimPlugins; };
    in
    {
      darwinConfigurations.mac-m1 = import ./hosts/mac-m1.nix (commonArgs // {
        inherit nix-darwin;
      });

      homeConfigurations = {
        al2-x86_64 = import ./hosts/al2-x86_64.nix commonArgs;
        al2-aarch64 = import ./hosts/al2-aarch64.nix commonArgs;
        al2023-x86_64 = import ./hosts/al2023-x86_64.nix commonArgs;
      };

      darwinPackages = self.darwinConfigurations.mac-m1.pkgs;

      # nix run .#activate — auto-detects host type and applies config
      apps = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          activate = {
            type = "app";
            program = toString (pkgs.writeShellScript "activate" ''
              set -e
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
            '');
          };
          update = {
            type = "app";
            program = toString (pkgs.writeShellScript "update" ''
              nix flake update
            '');
          };
        });
    };
}
