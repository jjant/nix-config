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
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).

set -euo pipefail

exec mac-ssh \
  -o BatchMode=yes -o ConnectTimeout=5 \
  -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \
  copy
