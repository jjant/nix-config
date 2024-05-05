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

  outputs =
    inputs @ { self
    , nix-darwin
    , nixpkgs
    , home-manager
    , ...
    }:
    let
      hosts = import ./hosts;
      inherit (nixpkgs) lib;

      # Filters all inputs with name `vim-plugin:owner/repo`
      # and removes the `vim-plugin:` prefix from the name.
      vimPlugins = myInputs:
        lib.mapAttrs'
          (name: value: {
            name = lib.removePrefix "vim-plugin:" name;
            inherit value;
          })
          (lib.filterAttrs (name: _: lib.hasPrefix "vim-plugin:" name) myInputs);
    in
    {
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
              extraSpecialArgs = {
                vimPlugins = vimPlugins inputs;
              };

              useGlobalPkgs = true;
              useUserPackages = true;
              users.jjantdev = {
                home.stateVersion = "23.11";
                home.homeDirectory = nixpkgs.lib.mkForce "/Users/jjantdev";

                imports = [
                  ./users/jjantdev
                  ({ pkgs, ... }: {
                    home.packages = [
                      pkgs.htop
                      # pkgs.jetbrains.idea-ultimate
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
