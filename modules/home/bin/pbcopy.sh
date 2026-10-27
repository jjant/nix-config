#!/usr/bin/env bash
# pbcopy — on a Linux dev desk, copy stdin to the Mac's clipboard.
#
# Transport: the same reverse tunnel as `open` (see modules/home/bin/open.sh
# and modules/darwin/openssh.nix) — localhost:2022 reaches the Mac's sshd,
# where the forced-command receiver (modules/darwin/mac-open-recv.sh) accepts
# the fixed mode token `copy` and pipes stdin into the Mac's own pbcopy.
#
# Fails fast instead of hanging: callers like fish's Ctrl-X run pbcopy
# implicitly. BatchMode rules out prompts, ConnectTimeout covers a stale
# forward (the desk's 2022 listener accepts, but the Mac never sends its
# banner), and ServerAlive drops a connection whose Mac went to sleep.
#
# ssh is nixpkgs' (pinned by resholve), as in modules/home/hostctl.nix: AL2's
# OpenSSH 7.4 predates StrictHostKeyChecking=accept-new. `-F /dev/null`
# because nixpkgs' ssh can't parse AL2023's system config; nothing in any
# config applies to localhost:2022, and the agent comes from SSH_AUTH_SOCK.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).

set -euo pipefail

port="${MAC_OPEN_PORT:-2022}"
mac="${MAC_OPEN_USER:-jjantdev}@localhost"
ctl="$HOME/.ssh/mac-open-%r@%h:%p"

exec ssh -F /dev/null -p "$port" -o StrictHostKeyChecking=accept-new \
  -o ControlMaster=auto -o "ControlPath=$ctl" -o ControlPersist=10s \
  -o BatchMode=yes -o ConnectTimeout=5 \
  -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \
  "$mac" copy
