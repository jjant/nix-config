{ lib, ... }:
let
  user = "jjantdev";

  # Dev desktop aliases -> full internal hostnames.
  hosts = {
    "al2-x86_64" = "dev-dsk-jjantdev-1a-4f02b3bf.eu-west-1.amazon.com";
    "al2-aarch64" = "dev-dsk-jjantdev-1a-51a25ad7.eu-west-1.amazon.com";
    "al2023-x86_64" = "dev-dsk-jjantdev-1a-0e9604fc.eu-west-1.amazon.com";
  };

  # Each alias carries its own ProxyCommand: SSH matches `Host` against the
  # name typed on the command line, not the resolved HostName, so the WSSH
  # `Host dev-dsk-*.amazon.com` block never applies to these aliases.
  hostBlock = alias: hostname: ''
    Host ${alias}
      HostName ${hostname}
      User ${user}
      ProxyCommand /usr/local/bin/wssh proxy %h
      ServerAliveInterval 15
      ServerAliveCountMax 44
  '';

  hostBlocks = lib.concatStringsSep "\n" (lib.mapAttrsToList hostBlock hosts);

  includeLine = "Include ~/.ssh/config.d/hosts";
in
{
  # nix owns this file; it is pulled in via an `Include` from ~/.ssh/config,
  # which itself is owned by WSSH and must not be clobbered by home-manager.
  home.file.".ssh/config.d/hosts".text = ''
    # Managed by nix-darwin (modules/home/ssh.nix). Do not edit by hand.
    ${hostBlocks}
    Host *
      # Silence OpenSSH 10's "not using a post-quantum key exchange" warning.
      # The client already prefers PQ KEX; this fires when the server lacks it
      # (e.g. internal git/dev-desktop servers). Only mutes the PQ-KEX warning,
      # not other weak-crypto warnings. Real fix is server-side.
      WarnWeakCrypto no-pq-kex
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      ControlMaster auto
      ControlPath ~/.ssh/ssh-%r@%h:%p
      ControlPersist 30m
  '';

  # Ensure the WSSH-owned ~/.ssh/config pulls in the nix-managed hosts file.
  # Idempotent: only appended if not already present.
  home.activation.sshIncludeHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh"
    if [ ! -e "$cfg" ]; then
      touch "$cfg"
      chmod 600 "$cfg"
    fi
    if ! grep -qxF '${includeLine}' "$cfg" 2>/dev/null; then
      if [ -n "$DRY_RUN_CMD" ]; then
        echo "[dry-run] would add '${includeLine}' to $cfg"
      else
        printf '\n%s\n' '${includeLine}' >> "$cfg"
      fi
    fi
  '';
}
