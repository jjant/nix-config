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

    "vim-plugin:VonHeikemen/lsp-zero.nvim" = {
      url = "github:VonHeikemen/lsp-zero.nvim";
      flake = false;
    };

    "vim-plugin:neovim/nvim-lspconfig" = {
      url = "github:neovim/nvim-lspconfig";
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
    };
}
