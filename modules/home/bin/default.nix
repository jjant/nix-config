{ pkgs, lib, ... }:
let
  # Shared with fish.nix, which interpolates tmux-sessionizer's store path.
  scripts = import ./packages.nix { inherit pkgs; };
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
    # Linux-only: on macOS `open` would shadow the real one, `code` must stay
    # VS Code's own CLI, and xdg-open's callers don't exist there.
    ++ lib.optionals pkgs.stdenv.isLinux [
      scripts.open
      scripts.xdg-open
      scripts.code
    ];

  # For URL-opening flows that honor $BROWSER instead of (or before)
  # xdg-open: gh, cargo, and crucially Python's stdlib webbrowser (aws sso
  # login and friends), which only tries xdg-open when DISPLAY or
  # WAYLAND_DISPLAY is set — on these headless hosts BROWSER is its only
  # hook. Store-pinned so it works even where PATH lacks the profile bin.
  home.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    BROWSER = "${scripts.open}/bin/open";
  };
}
