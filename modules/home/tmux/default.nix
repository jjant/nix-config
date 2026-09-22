{ pkgs, lib, ... }:
let
  dracula = {
    plugin = pkgs.tmuxPlugins.dracula;
    extraConfig = ''
      set -g @dracula-show-powerline true
      set -g @dracula-show-fahrenheit false
      set -g @dracula-show-left-icon session
      set -g @dracula-network-bandwidth false
    '';
  };

  # The tmux server deliberately stays in the SSH session cgroup so a failed
  # systemd user manager cannot take every session down with it. Each pane
  # enters the bounded user slice independently through the host's systemd-run
  # client. This also avoids relying on tmux's built-in transient scopes: on
  # the cloud desktops tmux is linked against a newer libsystemd than the host
  # manager, and the scopes are created without the pane actually moving into
  # them.
  scopedFish = pkgs.writeShellScript "tmux-scoped-fish" ''
    marker=$1
    shift

    ${pkgs.coreutils}/bin/touch "$marker" || exit 125
    # tmux normally marks its default shell as a login shell through argv[0].
    # paneShell's shebang loses that marker before reaching fish, so restore
    # the equivalent mode explicitly.
    exec ${lib.getExe pkgs.fish} --login "$@"
  '';

  paneShell = pkgs.writeShellScriptBin "tmux-pane-shell" ''
    fish=${lib.getExe pkgs.fish}

    # Avoid nesting scopes if a shell recursively starts another login shell.
    if ${pkgs.gnugrep}/bin/grep -q '/tmux-panes\.slice/' /proc/self/cgroup; then
      exec "$fish" --login "$@"
    fi

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    systemd_run=/usr/bin/systemd-run

    # Availability wins over containment: a dead or missing user manager must
    # never make a tmux pane impossible to open.
    if [ ! -x "$systemd_run" ] || [ ! -S "$runtime_dir/bus" ]; then
      exec "$fish" --login "$@"
    fi

    marker_dir=$(${pkgs.coreutils}/bin/mktemp -d "$runtime_dir/tmux-pane-scope.XXXXXX") ||
      exec "$fish" --login "$@"
    marker="$marker_dir/started"

    pane_memory_high="''${TMUX_PANE_MEMORY_HIGH:-24G}"
    pane_memory_max="''${TMUX_PANE_MEMORY_MAX:-infinity}"

    "$systemd_run" \
      --user \
      --scope \
      --collect \
      --quiet \
      --same-dir \
      --slice=tmux-panes.slice \
      --unit="tmux-pane-$PPID-$$" \
      --property="MemoryHigh=$pane_memory_high" \
      --property="MemoryMax=$pane_memory_max" \
      --property=OOMPolicy=kill \
      -- \
      ${scopedFish} "$marker" "$@"
    status=$?

    # systemd-run returns the shell's status after a successful launch. The
    # marker distinguishes that from failure to create the scope, in which
    # case start an ordinary unbounded shell instead of closing the pane.
    if [ ! -e "$marker" ]; then
      ${pkgs.coreutils}/bin/rmdir "$marker_dir" 2>/dev/null || true
      echo "tmux: systemd pane scope unavailable; starting unbounded shell" >&2
      exec "$fish" --login "$@"
    fi

    ${pkgs.coreutils}/bin/rm -f "$marker"
    ${pkgs.coreutils}/bin/rmdir "$marker_dir" 2>/dev/null || true
    exit "$status"
  '';
in
{
  # All pane scopes share a host-level safety envelope. MemoryHigh throttles
  # and reclaims first; MemoryMax is deliberately aggregate-only during the
  # initial rollout so a legitimate large pane may exceed its own 24 GiB soft
  # threshold when the rest of the machine is idle.
  systemd.user.slices.tmux-panes = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "tmux pane memory pool";
      # Reloading resource properties is safe, but stopping the slice would
      # terminate every live pane during an unrelated home-manager switch.
      X-RestartIfChanged = false;
    };
    Slice = {
      MemoryHigh = "48G";
      MemoryMax = "64G";
      MemorySwapMax = "4G";
    };
  };

  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    clock24 = true;
    keyMode = "vi";
    plugins = [ dracula ];
    historyLimit = 30000;
    escapeTime = 0;
    extraConfig =
      builtins.readFile ./tmux.conf
      + (
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''

            # copy-mode `y`: copy to the macOS system clipboard.
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
          ''
        else
          ''

            # copy-mode `y` on the Linux cloud desktops: there is no pbcopy, and
            # copying to the remote's own clipboard is useless over SSH. Emit
            # OSC52 instead (`set-clipboard on`), so tmux hands the selection to
            # the local terminal (alacritty), which writes it to the Mac
            # clipboard through the SSH session.
            set -g set-clipboard on
            bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

            # Put every new pane (and every agent command it launches) in a
            # bounded cgroup while leaving the tmux server itself outside.
            set -g default-shell '${paneShell}/bin/tmux-pane-shell'

            # Preserve the layout and scrollback if systemd kills an offending
            # pane, and keep the server around even if no sessions remain.
            set -g remain-on-exit failed
            set -s exit-empty off

            # Prefix+C opens a pane with a higher soft threshold. It remains
            # subject to the aggregate tmux-panes.slice hard limit.
            bind C new-window -c "#{pane_current_path}" -e TMUX_PANE_MEMORY_HIGH=48G
          ''
      );
  };
}
