{ lib, pkgs, ... }:
let
  user = "jjantdev";

  # Options that only make sense on macOS:
  # - `WarnWeakCrypto` only exists in OpenSSH 10+. The cloud desktops ship an
  #   older OpenSSH that rejects the option outright ("Bad configuration
  #   option: warnweakcrypto"), which aborts ssh and breaks git clones.
  # - `IdentityAgent` points at the 1Password mac agent socket
  #   (~/Library/Group Containers/...), a path that only exists on macOS. On
  #   the dev desks auth goes through the wssh ProxyCommand anyway.
  darwinOnlyOptions = lib.optionalString pkgs.stdenv.isDarwin ''

      # Silence OpenSSH 10's "not using a post-quantum key exchange" warning.
      # The client already prefers PQ KEX; this fires when the server lacks it
      # (e.g. internal git/dev-desktop servers). Only mutes the PQ-KEX warning,
      # not other weak-crypto warnings. Real fix is server-side.
      WarnWeakCrypto no-pq-kex
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';

  # Dev desktop aliases -> full internal hostnames.
  hosts = {
    "al2-x86_64" = "dev-dsk-jjantdev-1a-4f02b3bf.eu-west-1.amazon.com";
    "al2-aarch64" = "dev-dsk-jjantdev-1a-51a25ad7.eu-west-1.amazon.com";
    "al2023-x86_64" = "dev-dsk-jjantdev-1a-0e9604fc.eu-west-1.amazon.com";
  };

  # Each alias carries its own ProxyCommand: SSH matches `Host` against the
  # name typed on the command line, not the resolved HostName, so the WSSH
  # `Host dev-dsk-*.amazon.com` block never applies to these aliases.
  #
  # `ForwardAgent yes` forwards the local 1Password SSH agent to the dev desks
  # so they can authenticate Git pushes to GitHub. The private key never leaves
  # 1Password on the Mac; only signing requests travel back over the existing
  # SSH connection. Scoped to these trusted hosts only (see `ForwardAgent no`
  # on `Host *` below).
  hostBlock = alias: hostname: ''
    Host ${alias}
      HostName ${hostname}
      User ${user}
      ProxyCommand /usr/local/bin/wssh proxy %h
      ForwardAgent yes
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
    Host *${darwinOnlyOptions}
      # Default-deny agent forwarding; only the dev-dsk aliases above opt in.
      ForwardAgent no
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
