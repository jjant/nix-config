{ nix-darwin, lib, ... }:
let
  hosts =
    lib.mapAttrs (hostName: host: host // { name = hostName; }) {

      # Work laptop
      endeavour = {
        type = "nix-darwin";
        platform = "aarch64-darwin";
      };
      # Cloud desktop
      discovery = {
        type = "home-manager";
        platform = "aarch64-linux";
      };
    };

  buildDarwinHost = { host, configuration }: {
    darwinConfigurations.${host.name} = nix-darwin.lib.darwinSystem {
      # TODO: Fill in modules
      modules = [ ];
    };
  };
in
{
  inherit hosts;

}
