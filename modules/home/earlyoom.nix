{ pkgs, lib, ... }:
{
  # earlyoom: userspace OOM killer for the Linux cloud desktops.
  #
  # The CDs have no swap, so when a pile of kiro sessions exhausts RAM the
  # kernel starts evicting executable pages and the host thrashes into a
  # hard lockup long before the kernel OOM killer reacts — the only way out
  # is a reboot from the CDD website. earlyoom watches MemAvailable and
  # SIGTERMs the biggest offender while the host is still responsive.
  #
  # It runs *unprivileged* as a systemd user service: it can then only kill
  # our own processes, which is exactly the population we want culled
  # (kiro-cli/bun agent sessions), and it keeps home-manager fully in charge
  # — no sudo, no system unit. Root-owned daemons are out of reach, but
  # they're not the ones ballooning.
  #
  # The user manager (and thus this service) starts at first login and
  # stops at last logout. That covers the failure mode — memory only piles
  # up while we're logged in running agents. `loginctl enable-linger` would
  # extend it to boot time, but needs root, so it's deliberately not
  # assumed here.
  systemd.user.services.earlyoom = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Early OOM Daemon (user, unprivileged)";
      # Docs recommend not restarting too aggressively: if earlyoom itself
      # gets OOM-killed the situation is already dire; backoff is fine.
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };

    Service = {
      # -m 4,2: SIGTERM below 4% available RAM (~5 GiB on a 123 GiB host),
      #   escalate to SIGKILL below 2%. Absolute headroom is plenty at that
      #   point; the defaults (10%) would fire with 12 GiB still free.
      # --avoid: never pick the session plumbing — killing tmux would take
      #   down every kiro session at once, and sshd/fish/nvim are cheap but
      #   painful losses. Matched against /proc/<pid>/comm, so tmux shows up
      #   as "tmux: server"/"tmux: client" (hence tmux.*).
      # --prefer: bias the score toward agent processes (kiro-cli,
      #   kiro-cli-chat, bun workers, node) so a runaway session is chosen
      #   over anything else at equal size.
      # --ignore-root-user: essential when unprivileged. earlyoom always
      #   targets the highest-scoring process and, on EPERM, just sleeps 1s
      #   and retries (kill.c) — without this flag it can fixate on a
      #   root-owned hog (falcon-sensor is routinely the single largest
      #   process on the CDs) and never kill anything.
      # -r 3600: memory report once an hour instead of the default every
      #   second (~86k journal lines/day). Kills are always logged
      #   regardless of the report interval.
      ExecStart = ''
        ${pkgs.earlyoom}/bin/earlyoom \
          -m 4,2 \
          -r 3600 \
          --ignore-root-user \
          --avoid '^(tmux.*|sshd|fish|nvim|systemd.*)$' \
          --prefer '^(kiro-cli.*|bun|node)$'
      '';
      Restart = "on-failure";
      RestartSec = 10;
      # Make sure earlyoom itself is the last thing the kernel would kill,
      # and give it a slight scheduling edge so it stays responsive under
      # memory pressure (values chosen from the upstream system unit, minus
      # the bits that need root).
      OOMScoreAdjust = -100;
      Nice = -1;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
