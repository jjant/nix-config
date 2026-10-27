#!/usr/bin/env bash
# pbpaste — on a Linux dev desk, print the Mac's clipboard.
#
# Transport: the same reverse tunnel as `open` (see modules/home/bin/open.sh
# and modules/darwin/openssh.nix) — localhost:2022 reaches the Mac's sshd,
# where the forced-command receiver (modules/darwin/mac-open-recv.sh) accepts
# the fixed mode token `paste` and runs the Mac's own pbpaste. `-n` keeps ssh
# off our stdin, which the receiver never reads.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).

set -euo pipefail

port="${MAC_OPEN_PORT:-2022}"
mac="${MAC_OPEN_USER:-jjantdev}@localhost"
ctl="$HOME/.ssh/mac-open-%r@%h:%p"

exec ssh -n -p "$port" -o StrictHostKeyChecking=accept-new -o ControlMaster=auto \
  -o "ControlPath=$ctl" -o ControlPersist=10s "$mac" paste
