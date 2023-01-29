{
  description = "jjant's Nix Config";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        utils.follows = "flake-utils";
      };
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

    # TODO: Add impermanence, pre-commit-hooks

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    templates.url = "github:NixOS/templates";

    flake-utils.url = "github:numtide/flake-utils";

    "vim-plugin:LunarVim/darkplus.nvim" = {
      url = "github:LunarVim/darkplus.nvim";
      flake = false;
    };

    "vim-plugin:VonHeikemen/lsp-zero.nvim" = {
      url = "github:VonHeikemen/lsp-zero.nvim";
      flake = false;
    };

    # LSP Support
    "vim-plugin:neovim/nvim-lspconfig" = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    "vim-plugin:williamboman/mason.nvim" = {
      url = "github:williamboman/mason.nvim";
      flake = false;
    };
    "vim-plugin:williamboman/mason-lspconfig.nvim" = {
      url = "github:williamboman/mason-lspconfig.nvim";
      flake = false;
    };
    "vim-plugin:simrat39/rust-tools.nvim" = {
      url = "github:simrat39/rust-tools.nvim";
      flake = false;
    };

    # Autocompletion
    "vim-plugin:hrsh7th/nvim-cmp" = {
      url = "github:hrsh7th/nvim-cmp";
      flake = false;
    };
    "vim-plugin:hrsh7th/cmp-buffer" = {
      url = "github:hrsh7th/cmp-buffer";
      flake = false;
    };
    "vim-plugin:hrsh7th/cmp-path" = {
      url = "github:hrsh7th/cmp-path";
      flake = false;
    };
    "vim-plugin:saadparwaiz1/cmp_luasnip" = {
      url = "github:saadparwaiz1/cmp_luasnip";
      flake = false;
    };
    "vim-plugin:hrsh7th/cmp-nvim-lsp" = {
      url = "github:hrsh7th/cmp-nvim-lsp";
      flake = false;
    };
    "vim-plugin:hrsh7th/cmp-nvim-lua" = {
      url = "github:hrsh7th/cmp-nvim-lua";
      flake = false;
    };

    # Snippets
    "vim-plugin:L3MON4D3/LuaSnip" = {
      url = "github:L3MON4D3/LuaSnip";
      flake = false;
    };
    "vim-plugin:rafamadriz/friendly-snippets" = {
      url = "github:rafamadriz/friendly-snippets";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    {
      deploy = import ./nix/deploy.nix inputs;
      homeConfigurations = import ./nix/home-manager.nix inputs;
      # TODO: Add darwin configurations
    } // flake-utils.lib.eachSystem [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
    ]
      (localSystem: {
        # checks = import ./nix/checks.nix inputs localSystem;
        packages = {
          default = self.packages.${localSystem}.all;
        } // (import ./nix/host-drvs.nix inputs localSystem);

        pkgs = import nixpkgs {
          config.allowUnfree = true;
          config.allowAliases = true;
        };
      });
}
