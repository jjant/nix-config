{ self, deploy-rs, nixpkgs, ... }:
let
  inherit (nixpkgs) lib;

  hosts = (import ./hosts.nix).all;

  genNode = hostName: nixosCfg:
    let
      inherit (hosts.${hostName}) address hostPlatform remoteBuild;
      inherit (deploy-rs.lib.${hostPlatform}) activate;
    in {
      inherit remoteBuild;
      hostname = address;
      profiles.system.path = activate.nixos nixosCfg;
    };
in {
  user = "root";
  nodes = lib.mapAttrs genNode self.nixosConfigurations;
}
