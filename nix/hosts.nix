let
  hosts = {
    odyssey = {
      type = "home-manager";
      hostPlatform = "aarch64-linux";
      homeDirectory = "/home/jjantdev";
    };
    # TODO: Add mac
  };

  inherit (builtins) attrNames concatMap listToAttrs;

  filterAttrs = pred: set:
    listToAttrs (concatMap (name:
      let value = set.${name};
      in if pred name value then [{ inherit name value; }] else [ ])
      (attrNames set));

  systemPred = system:
    (_: v: builtins.match ".*${system}.*" v.hostPlatform != null);

  genFamily = filter: hosts: rec {
    all = filterAttrs filter hosts;

    nixos = genFamily (_: v: v.type == "nixos") all;
    nix-darwin = genFamily (_: v: v.type == "darwin") all;
    homeManager = genFamily (_: v: v.type == "home-manager") all;

    darwin = genFamily (systemPred "-darwin") all;
    linux = genFamily (systemPred "-linux") all;

    aarch64-linux = genFamily (systemPred "aarch64-linux") all;
  };
in genFamily (_: _: true) hosts
