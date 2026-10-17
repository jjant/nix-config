# Host configurations, generated from the registry in ../hosts/default.nix,
# plus the `nix flake check` gate that builds them.
{
  self,
  inputs,
  lib,
  hosts,
  ...
}:
let
  inherit (inputs) nixpkgs home-manager;

  vimPlugins = lib.mapAttrs' (name: value: {
    name = lib.removePrefix "vim-plugin:" name;
    inherit value;
  }) (lib.filterAttrs (name: _: lib.hasPrefix "vim-plugin:" name) inputs);

  isDarwin = host: host.os == "darwin";

  # A Linux cloud desktop. The hosts only differ in platform and prompt
  # tag; everything else lives in ../modules/home.
  mkHome =
    alias:
    { system, ... }@host:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit vimPlugins; };
      modules = [
        ../modules/home
        {
          home = {
            username = "jjantdev";
            homeDirectory = "/home/jjantdev";
            stateVersion = "23.11";
            sessionVariables.STARSHIP_HOST_ALIAS = alias;
          };
        }
      ]
      ++ lib.optional (host.atuinServer or false) ../modules/home/atuin-server.nix;
    };
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs (
      name: host:
      import ../hosts/${name}.nix {
        inherit (host) system;
        inherit self vimPlugins;
        inherit (inputs)
          nixpkgs
          home-manager
          nix-darwin
          nix-homebrew
          nix-vscode-extensions
          mac-app-util
          ;
      }
    ) (lib.filterAttrs (_: isDarwin) hosts);

    homeConfigurations = lib.mapAttrs mkHome (lib.filterAttrs (_: host: !isDarwin host) hosts);

    darwinPackages = self.darwinConfigurations.mac-m1.pkgs;
  };

  # `nix flake check` builds every host that can build on the current
  # platform (same attrs CI builds), so it works as a single local gate.
  perSystem =
    { system, ... }:
    {
      checks = lib.mapAttrs (
        name: host:
        if isDarwin host then
          self.darwinConfigurations.${name}.system
        else
          self.homeConfigurations.${name}.activationPackage
      ) (lib.filterAttrs (_: host: host.system == system) hosts);
    };
}
