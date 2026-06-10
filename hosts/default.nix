{ lib, ... }:
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
in
{
  inherit hosts;
}
