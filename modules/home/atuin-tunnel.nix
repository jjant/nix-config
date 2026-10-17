{ lib, pkgs, ... }:
let
  # The desk running the atuin sync server (atuinServer = true in ../../hosts).
  server = lib.head (
    lib.attrValues (lib.filterAttrs (_: host: host.atuinServer or false) (import ../../hosts))
  );
in
{
  # The other desks' counterpart to the Mac's launchd tunnel
  # (../darwin/atuin-tunnel.nix): forward localhost:8888 to the server's
  # loopback-only port (./atuin-server.nix) so `atuin sync` works here.
  #
  # Desk-to-desk ssh connects directly and authenticates with the desk's
  # short-lived SSH certificate. An open tunnel outlives it, but
  # reconnecting needs it renewed on this desk; until then systemd keeps
  # retrying and history stays local.
  #
  # A user service like earlyoom: up while we're logged in to this desk.
  systemd.user.services.atuin-tunnel = {
    Unit = {
      Description = "SSH tunnel to the atuin sync server on ${server.hostname}";
      # Never give up retrying; RestartSec already paces it.
      StartLimitIntervalSec = 0;
    };

    Service = {
      # nixpkgs' OpenSSH: AL2's 7.4 predates StrictHostKeyChecking=accept-new.
      ExecStart = lib.escapeShellArgs [
        "${pkgs.openssh}/bin/ssh"
        "-NT"
        # Ignore ~/.ssh/config (control master, dev-desk aliases): a plain,
        # dedicated connection.
        "-F"
        "/dev/null"
        # Exit (and let systemd retry) instead of idling without the forward,
        # prompting nobody can answer, or hanging on a dead connection.
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "BatchMode=yes"
        # Unattended first connection: trust the server's key on first use.
        "-o"
        "StrictHostKeyChecking=accept-new"
        "-o"
        "ServerAliveInterval=15"
        "-o"
        "ServerAliveCountMax=3"
        "-L"
        "127.0.0.1:8888:localhost:8888"
        "jjantdev@${server.hostname}"
      ];
      Restart = "always";
      RestartSec = 30;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
