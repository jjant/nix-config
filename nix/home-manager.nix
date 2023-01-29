{ self, home-manager, nixpkgs, templates, ... }@inputs:
let
  inherit (nixpkgs) lib;
  hosts = (import ./hosts.nix).homeManager.all;

  genModules = hostName:
    { homeDirectory, ... }:
    { config, pkgs, ... }: {
      imports = [ (../hosts + "/${hostName}") ];
      nix.registry = {
        nixpkgs.flake = nixpkgs;
        p.flake = nixpkgs;
        pkgs.flake = nixpkgs;
        templates.flake = templates;
      };

      home = {
        inherit homeDirectory;

        sessionVariables.NIX_PATH = lib.concatStringsSep ":" [
          "nixpkgs=${config.xdg.dataHome}/nixpkgs"
          "nixpkgs-overlays=${config.xdg.dataHome}/overlays"
        ];
        sessionVariables.LS_COLORS = "";
      };

      programs.fish.plugins = [ ];

      xdg = {
        dataFile = {
          nixpkgs.source = nixpkgs;
          overlays.source = ../nix/overlays;
        };
        configFile."nix/nix.conf".text = ''
          flake-registry = ${config.xdg.configHome}/nix/registry.json
          experimental-features = nix-command flakes
        '';
      };
    };

  # Filters all inputs with name `vim-plugin:owner/repo`
  # and removes the `vim-plugin:` prefix from the name.
  vimPlugins = myInputs:
    lib.mapAttrs' (name: value: {
      name = lib.removePrefix "vim-plugin:" name;
      value = value;
    }) (lib.filterAttrs (name: _: lib.hasPrefix "vim-plugin:" name) myInputs);

  genConfiguration = hostName:
    { hostPlatform, ... }@attrs:
    home-manager.lib.homeManagerConfiguration {
      pkgs = self.pkgs.${hostPlatform};
      modules = [ (genModules hostName attrs) ];
      extraSpecialArgs = { vimPlugins = vimPlugins inputs; };
    };
in lib.mapAttrs genConfiguration hosts
