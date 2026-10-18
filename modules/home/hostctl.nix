# hostctl: which hosts run the configuration on this flake's main, checked from
# any of them, and activating the ones that don't when asked (the Mac only on
# the Mac). The hosts and how to reach them come from the flake itself
# (../../parts/hostctl.nix).
{
  lib,
  pkgs,
  hostctl,
  ...
}:
{
  imports = [ hostctl.homeModules.default ];

  programs.hostctl = {
    enable = true;
    settings = {
      flake = "github:jjant/nix-config";
      # The Mac answers over its reverse tunnel with a forced command
      # (../darwin/mac-open-recv.sh), so hostctl sends that command's
      # `current-system` instead of its probe script. Only a user config may
      # set a probe, not the flake's inventory.
      hosts = lib.mapAttrs (_: _: { probe = "current-system"; }) (
        lib.filterAttrs (_: host: host.os == "darwin") (import ../../hosts)
      );
      # On the desks, nixpkgs' OpenSSH without any ssh config, as in
      # ./atuin-tunnel.nix: AL2's OpenSSH 7.4 predates the
      # StrictHostKeyChecking=accept-new hostctl relies on, and nixpkgs' can't
      # parse AL2023's system config. The desks reach each other directly with
      # their own SSH certificates, and the Mac with the agent forwarded from it.
      ssh = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        command = "${pkgs.openssh}/bin/ssh";
        options = [
          "-F"
          "/dev/null"
        ];
      };
    };
  };
}
