#!/usr/bin/env bash
# open — on a Linux dev desk, hand a file or URL to the Mac's native `open`.
#
# Mechanism: the Mac's ssh config (modules/home/ssh.nix) sets
#   RemoteForward 2022 localhost:22
# so this host's localhost:2022 reaches the Mac's sshd. We copy the file over
# and run the Mac's `open` on it. Auth uses the forwarded 1Password agent, so
# the Mac must (a) have Remote Login enabled and (b) authorize that key.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).
# Not handled: filenames with spaces, and HTML with local assets (css/img) —
# for asset-heavy pages copy the whole folder or serve over HTTP instead.

# shellcheck disable=SC2029  # remote `open $arg` is meant to expand client-side

set -euo pipefail

port="${MAC_OPEN_PORT:-2022}"
mac="${MAC_OPEN_USER:-jjantdev}@localhost"
ctl="$HOME/.ssh/mac-open-%r@%h:%p"
common=(-o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o "ControlPath=$ctl" -o ControlPersist=10s)

if [ "$#" -eq 0 ]; then
  echo "usage: open <file|url> ..." >&2
  exit 1
fi

for arg in "$@"; do
  if [ -e "$arg" ]; then
    src="$(realpath "$arg")"
    dst="/tmp/open-$(date +%s)-$(basename "$src")"
    scp -q -P "$port" "${common[@]}" "$src" "$mac:$dst"
    ssh -p "$port" "${common[@]}" "$mac" open "$dst"
  else
    ssh -p "$port" "${common[@]}" "$mac" open "$arg"
  fi
done
