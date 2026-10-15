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

      # Every host, keyed by config name; see ./hosts/default.nix.
      hosts = import ./hosts;
      isDarwin = host: lib.hasSuffix "-darwin" host.system;
      linuxHosts = lib.filterAttrs (_: host: !isDarwin host) hosts;
      darwinHosts = lib.filterAttrs (_: isDarwin) hosts;

      # The attribute that builds a host's full closure.
      hostAttr =
        name: host:
        if isDarwin host then
          "darwinConfigurations.${name}.system"
        else
          "homeConfigurations.${name}.activationPackage";

      # `activate`'s hostname -> config lookup, one case arm per desk.
      desksCases = lib.concatStringsSep "\n      " (
        lib.mapAttrsToList (
          name: host: "${lib.head (lib.splitString "." host.hostname)}) host=${name} ;;"
        ) (lib.filterAttrs (_: host: host ? hostname) linuxHosts)
      );

      # GitHub runner per Nix platform: every host is built natively.
      runners = {
        x86_64-linux = "ubuntu-latest";
        aarch64-linux = "ubuntu-24.04-arm";
        aarch64-darwin = "macos-15";
      };

      # A Linux cloud desktop. The hosts only differ in platform and prompt
      # tag; everything else lives in ../modules/home.
      mkHome =
        alias:
        { system, ... }:
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
      darwinConfigurations = lib.mapAttrs (
        name: host:
        import ./hosts/${name}.nix {
          inherit (host) system;
          inherit
            self
            nixpkgs
            home-manager
            vimPlugins
            nix-darwin
            nix-homebrew
            ;
          inherit (inputs) nix-vscode-extensions mac-app-util;
        }
      ) darwinHosts;

      homeConfigurations = lib.mapAttrs mkHome linuxHosts;

      darwinPackages = self.darwinConfigurations.mac-m1.pkgs;

      # `nix flake check` builds every host that can build on the current
      # platform (same attrs CI builds), so it works as a single local gate.
      checks = lib.genAttrs systems (
        system:
        lib.mapAttrs (
          name: host:
          if isDarwin host then
            self.darwinConfigurations.${name}.system
          else
            self.homeConfigurations.${name}.activationPackage
        ) (lib.filterAttrs (_: host: host.system == system) hosts)
      );

      # CI build matrix (`nix eval --json .#ciMatrix`), one entry per host.
      ciMatrix = lib.mapAttrsToList (name: host: {
        inherit name;
        os = runners.${host.system};
        attr = hostAttr name host;
      }) hosts;

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
                else
                  # Pick the desk's config by short hostname (./hosts). The
                  # config name becomes STARSHIP_HOST_ALIAS, which `code` and
                  # `zed` use as the ssh destination back to this desk, so a
                  # guessed config would attach editors to another desk.
                  # ACTIVATE_HOST=<config> overrides the lookup.
                  host="''${ACTIVATE_HOST:-}"
                  if [ -z "$host" ]; then
                    case "$(hostname -s)" in
                      ${desksCases}
                      *)
                        echo "activate: $(hostname -s) is not in hosts/default.nix;" \
                          "add it there or set ACTIVATE_HOST=<config>" >&2
                        exit 1
                        ;;
                    esac
                  fi

                  if command -v home-manager &>/dev/null; then
                    home-manager switch --flake .#"$host" "$@"
                  else
                    nix run home-manager -- switch --flake .#"$host" "$@"
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
