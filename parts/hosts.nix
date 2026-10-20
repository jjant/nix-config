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

  # The commit with uncommitted changes a configuration is built from
  # (`<rev>-dirty`). `nix run .#activate` evaluates a dirty tree as a copy
  # without it, which has it in ../.dirty-rev instead (./apps.nix).
  dirtyRev =
    self.dirtyRev
      or (if builtins.pathExists ../.dirty-rev then lib.fileContents ../.dirty-rev else null);

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
      extraSpecialArgs = {
        inherit vimPlugins;
        inherit (inputs) zenoh-ts hostctl;
      };
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
        # How hostctl tells a generation activated from uncommitted changes.
        # A clean one records no revision, so that a commit that doesn't
        # change a desk doesn't make it outdated.
        {
          home.extraBuilderCommands = lib.optionalString (dirtyRev != null) ''
            echo -n ${lib.escapeShellArg dirtyRev} > $out/configuration-revision
          '';
        }
      ]
      # One desk serves atuin sync; the rest tunnel to it.
      ++ [
        (
          if host.atuinServer or false then
            ../modules/home/atuin-server.nix
          else
            ../modules/home/atuin-tunnel.nix
        )
      ];
    };
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs (
      name: host:
      import ../hosts/${name}.nix {
        inherit (host) system;
        inherit vimPlugins;
        revision = self.rev or dirtyRev;
        inherit (inputs)
          nixpkgs
          home-manager
          nix-darwin
          nix-homebrew
          nix-vscode-extensions
          mac-app-util
          zenoh-ts
          hostctl
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
