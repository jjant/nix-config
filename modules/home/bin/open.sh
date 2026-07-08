#!/usr/bin/env bash
# open — on a Linux dev desk, hand a file, directory, or URL to the Mac's
# native `open`.
#
# Transport: the Mac's ssh config (modules/home/ssh.nix) sets
#   RemoteForward 2022 localhost:22
# so this host's localhost:2022 reaches the Mac's sshd. A file or directory is
# streamed over as one gzip'd tar (single SSH connection, compressed, few
# round-trips — far faster than per-file scp for trees), extracted into a temp
# dir on the Mac, and handed to the Mac's `open`. `pv` draws a transfer
# progress bar so a large copy never looks stuck. URLs pass straight through.
#
# Auth uses the forwarded 1Password agent, so the Mac must have Remote Login
# enabled and authorize that key.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).
# Edge: paths containing a single quote aren't handled.

# shellcheck disable=SC2029  # remote commands intentionally expand client-side

set -euo pipefail

port="${MAC_OPEN_PORT:-2022}"
mac="${MAC_OPEN_USER:-jjantdev}@localhost"
ctl="$HOME/.ssh/mac-open-%r@%h:%p"
ssh_opts=(-p "$port" -o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o "ControlPath=$ctl" -o ControlPersist=10s)

if [ "$#" -eq 0 ]; then
  echo "usage: open <file|dir|url> ..." >&2
  exit 1
fi

for arg in "$@"; do
  # Not a local path -> treat as a URL / bundle id and let the Mac resolve it.
  if [ ! -e "$arg" ]; then
    ssh "${ssh_opts[@]}" "$mac" "open '$arg'"
    continue
  fi

  src="$(realpath "$arg")"
  base="$(basename "$src")"
  parent="$(dirname "$src")"
  dest="/tmp/open-$(date +%s)-$$"
  bytes="$(du -sb "$src" | cut -f1)"

  printf '%s\n' "-> copying $base ($(numfmt --to=iec "$bytes")) to the Mac..." >&2

  # Uncompressed tar -> pv (live throughput readout) -> gzip -> extract and
  # open on the Mac, all over one SSH connection.
  tar cf - -C "$parent" -- "$base" |
    pv -btr |
    gzip |
    ssh "${ssh_opts[@]}" "$mac" "mkdir -p '$dest' && tar xzf - -C '$dest' && open '$dest/$base'"
done
