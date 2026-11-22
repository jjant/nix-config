{ lib, pkgs, ... }:
let
  user = "jjantdev";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # Options that only make sense on macOS:
  # - `WarnWeakCrypto` only exists in OpenSSH 10+. The cloud desktops ship an
  #   older OpenSSH that rejects the option outright ("Bad configuration
  #   option: warnweakcrypto"), which aborts ssh and breaks git clones.
  # - `IdentityAgent` points at the 1Password mac agent socket
  #   (~/Library/Group Containers/...), a path that only exists on macOS. The
  #   dev desks use the agent forwarded from the Mac, or their own SSH
  #   certificates between desks (see ./atuin-tunnel.nix).
  darwinOnlyOptions = lib.optionalString isDarwin ''

    # Silence OpenSSH 10's "not using a post-quantum key exchange" warning.
    # The client already prefers PQ KEX; this fires when the server lacks it
    # (e.g. internal git/dev-desktop servers). Only mutes the PQ-KEX warning,
    # not other weak-crypto warnings. Real fix is server-side.
    WarnWeakCrypto no-pq-kex
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';

  desks = lib.filterAttrs (_: host: host ? hostname) (import ../../hosts);
  deskBlock =
    alias: desk:
    let
      names = "${alias} ${desk.hostname}";
      atuin = lib.optionalString (isDarwin && (desk.atuinServer or false)) " ${alias}-atuin-tunnel";
    in
    ''
      Host ${names}${atuin}
        HostName ${desk.hostname}
        User ${user}
        ServerAliveInterval 15
        ServerAliveCountMax 44
    ''
    + lib.optionalString isDarwin ''
        ProxyCommand /usr/local/bin/wssh proxy %h

      Host ${names}
        # Both names reuse the alias's master, which owns the desk's port 2022.
        ControlPath ~/.ssh/ssh-%r@${alias}:%p
        ForwardAgent yes
        RemoteForward 2022 localhost:22
    '';

  includeLine = "Include ~/.ssh/config.d/hosts";
in
{
  # nix owns this file; it is pulled in via an `Include` from ~/.ssh/config,
  # which itself is owned by WSSH and must not be clobbered by home-manager.
  home.file.".ssh/config.d/hosts".text = ''
    # Managed by nix-darwin (modules/home/ssh.nix). Do not edit by hand.
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList deskBlock desks)}
    Host *${darwinOnlyOptions}
      ForwardAgent no
      ControlMaster auto
      ControlPath ~/.ssh/ssh-%r@%n:%p
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
