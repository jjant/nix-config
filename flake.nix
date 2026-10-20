{
  description = "jjant's nix config";

  # Lets `nix run github:jjant/nix-config#activate` on a fresh machine pull
  # from the CI-filled cache. Only honored for trusted users (see README
  # first-time setup); untrusted users get a warning and build locally.
  # On configured machines the same settings live in nix.conf (system-wide
  # via modules/darwin on the mac, per-user via modules/home on Linux).
  nixConfig = {
    extra-substituters = [ "https://jjant-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "jjant-nix.cachix.org-1:g3Dup2VOxdS2kNwIxoQ7JVl0W/mhrTHv7jvFHOYAFd4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Module system for the flake's own outputs; see ./parts.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `master` pairs with nixpkgs-unstable; nix-darwin asserts the two match.
    # (The repo moved from LnL7/nix-darwin to the nix-darwin org.)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Which hosts run this flake's current configuration, and updating the
    # ones that don't on request; see modules/home/hostctl.nix and
    # parts/hostctl.nix.
    hostctl = {
      url = "github:jjant/hostctl";
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

    # Source for zenoh-bridge-remote-api (not in nixpkgs); see
    # modules/home/zenoh.nix. Pinned to a release tag; bump the tag to upgrade.
    zenoh-ts = {
      url = "github:eclipse-zenoh/zenoh-ts/1.10.1";
      flake = false;
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
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Platforms this flake's hosts run on. perSystem outputs (apps, checks,
      # formatter) are generated for each.
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Every host, keyed by config name; see ./hosts/default.nix.
      _module.args.hosts = import ./hosts;

      imports = [
        ./parts/hosts.nix
        ./parts/apps.nix
        ./parts/hostctl.nix
      ];

      # `nix fmt` — official Nix formatting (RFC 166) via the treefmt wrapper,
      # which handles tree-walking (plain nixfmt deprecated directory args).
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };
    };
}
