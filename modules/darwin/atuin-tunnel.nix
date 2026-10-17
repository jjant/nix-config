{ lib, ... }:
let
  # The desk running the atuin sync server (atuinServer = true in ../../hosts).
  server = lib.head (
    lib.attrNames (lib.filterAttrs (_: host: host.atuinServer or false) (import ../../hosts))
  );
in
{
  # Keeps this Mac's localhost:8888 forwarded to the desk's loopback-only
  # atuin server (../home/atuin-server.nix), so `atuin sync` works without
  # an interactive ssh session open. launchd restarts ssh whenever it drops
  # (VPN off, sleep, desk reboot); sync just fails until it reconnects.
  launchd.user.agents.atuin-tunnel.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/ssh"
      "-NT"
      # A dedicated connection: riding (or becoming) the interactive control
      # master would tie the tunnel's lifetime to those sessions.
      "-o"
      "ControlMaster=no"
      "-o"
      "ControlPath=none"
      # Nothing on the desk needs this connection's agent.
      "-o"
      "ForwardAgent=no"
      # Exit (and let launchd retry) instead of idling without the forward,
      # prompting nobody can answer, or hanging on a dead connection.
      "-o"
      "ExitOnForwardFailure=yes"
      "-o"
      "BatchMode=yes"
      "-o"
      "ServerAliveInterval=15"
      "-o"
      "ServerAliveCountMax=3"
      "-L"
      "127.0.0.1:8888:localhost:8888"
      # The desk's alias minus its RemoteForward (../home/ssh.nix).
      "${server}-atuin-tunnel"
    ];
    KeepAlive = true;
    RunAtLoad = true;
    # Retry every 30s rather than spinning while off the VPN.
    ThrottleInterval = 30;
    StandardErrorPath = "/Users/jjantdev/Library/Logs/atuin-tunnel.log";
  };
}
