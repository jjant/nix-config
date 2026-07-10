#!/usr/bin/env bash
# open — on a Linux dev desk, hand a file, directory, or URL to the Mac's
# native `open`.
#
# Transport: the Mac's ssh config (modules/home/ssh.nix) sets
#   RemoteForward 2022 localhost:22
# so this host's localhost:2022 reaches the Mac's sshd, where a locked-down
# forced command (modules/darwin/mac-open-recv.sh, pinned via the authorized
# key's command="...") receives the request.
#
# Protocol: this client sends only a fixed mode token as the ssh command --
# `url` or `file` -- and the payload on stdin:
#   - url:  the URL text on stdin; the Mac opens it (web URLs only).
#   - file: a zstd-compressed tar of the file/dir on stdin (single connection,
#           few round-trips -- far faster than per-file scp for trees). The Mac
#           decompresses, extracts to a temp dir, and opens it. `pv` draws a
#           client-side transfer progress bar so a large copy never looks stuck.
# The mode token is untrusted but inert: the forced command only matches it
# against its fixed vocabulary, never executes it. No path or URL ever rides in
# the command string, so there is no remote-shell quoting/injection surface.
#
# Auth uses the forwarded 1Password agent, so the Mac must have Remote Login
# enabled and authorize that key.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).

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
  # Not a local path -> treat as a URL and let the Mac resolve it.
  if [ ! -e "$arg" ]; then
    printf '%s' "$arg" | ssh "${ssh_opts[@]}" "$mac" url
    continue
  fi

  src="$(realpath "$arg")"
  base="$(basename "$src")"
  parent="$(dirname "$src")"
  bytes="$(du -sb "$src" | cut -f1)"

  printf '%s\n' "-> copying $base ($(numfmt --to=iec "$bytes")) to the Mac..." >&2

  # Stream the target as one zstd-compressed tar over a single SSH connection;
  # the Mac decompresses, extracts, and opens it. pv gives a live throughput
  # readout. zstd is far faster than gzip at a better ratio, and stores
  # already-compressed data verbatim so there is no downside on such inputs.
  tar cf - -C "$parent" -- "$base" | pv -btr | zstd | ssh "${ssh_opts[@]}" "$mac" file
done
