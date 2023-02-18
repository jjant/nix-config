{ self, pkgs, ... }:
system:
let
  inherit (pkgs.${system}) lib linkFarm;

  hosts = import ./hosts.nix;

  # nixosDrvs = lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel)
  #   self.nixosConfigurations;
  nixosDrvs = { };

  # darwinDrvs =
  #   lib.mapAttrs (_: darwin: darwin.system) self.darwinConfigurations;
  darwinDrvs = { };

  homeDrvs =
    lib.mapAttrs (_: home: home.activationPackage) self.homeConfigurations;

  hostDrvs = nixosDrvs // homeDrvs // darwinDrvs;

  structuredHostDrvs = lib.mapAttrsRecursiveCond
    (hostAttr:
      !(hostAttr ? "type" && (lib.elem hostAttr.type [ "darwin" "homeManager" "nixos" ])))
    (path: _: hostDrvs.${lib.last path})
    hosts;

  structuredHostFarms = lib.mapAttrsRecursiveCond
    (as: !(lib.any lib.isDerivation (lib.attrValues as)))
    (path: values:
      (linkFarm (lib.concatStringsSep "-" path)
        (lib.mapAttrsToList (name: path: { inherit name path; }) values))
      // values)
    structuredHostDrvs;
in
structuredHostFarms
