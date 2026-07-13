{ pkgs, lib, ... }:
let
  # Shared with fish.nix, which interpolates tmux-sessionizer's store path.
  scripts = import ./packages.nix { inherit pkgs lib; };
in
{
  home.packages =
    (with scripts; [
      tmux-sessionizer
      brazil-open-package
      brazil-workspace-from-package
      dev-desk-tunnel
      pnew
      cr-open
    ])
    # Linux-only: on macOS `open` would shadow the real one.
    ++ lib.optionals pkgs.stdenv.isLinux [ scripts.open ];
}
