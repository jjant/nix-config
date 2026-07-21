#!/usr/bin/env bash
# code — on a Linux dev desk, open files/dirs in VS Code ON THE MAC, attached
# back to this host over Remote-SSH. `code .` in a repo here opens that repo
# in a remote VS Code window on the Mac; nothing is copied (unlike `open`,
# which ships a tarball) — VS Code SSHes back to this host on its own.
#
# Transport: the same reverse tunnel as `open` (see modules/home/bin/open.sh
# and modules/darwin/openssh.nix) — localhost:2022 reaches the Mac's sshd,
# where the forced-command receiver (modules/darwin/mac-open-recv.sh) accepts
# the fixed mode token `code` and reads three payload lines from stdin:
#   kind  "folder" or "file" (decided here, where we can stat the path)
#   host  ssh destination the Mac should attach VS Code to
#   path  absolute path on this host
# All three are data, never code: the receiver validates them against a closed
# grammar and builds the vscode-remote:// URI itself, so nothing
# client-controlled rides in a command string.
#
# Host identity: STARSHIP_HOST_ALIAS (e.g. "al2023-x86_64") is this desk's
# alias in the Mac's ssh config (modules/home/ssh.nix), so VS Code piggybacks
# on the alias's wssh ProxyCommand and any live ControlMaster socket — usually
# no fresh Midway auth. Fallback: the FQDN, which the Mac's WSSH-owned
# `Host dev-dsk-*.amazon.com` block also knows how to reach.
#
# Inside a VS Code integrated terminal (VSCODE_IPC_HOOK_CLI set) we defer to
# VS Code's own remote CLI if it exists, in case we shadow it on PATH — so
# `code file` opens in the window you're typing in, not a new one.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).

set -euo pipefail

# Already inside a VS Code remote window? Hand off to its bundled CLI.
# Newer server layout first, then the classic one.
if [ -n "${VSCODE_IPC_HOOK_CLI:-}" ]; then
  for cli in "$HOME"/.vscode-server/cli/servers/*/server/bin/remote-cli/code \
    "$HOME"/.vscode-server/bin/*/bin/remote-cli/code; do
    if [ -x "$cli" ]; then
      exec "$cli" "$@"
    fi
  done
fi

port="${MAC_OPEN_PORT:-2022}"
mac="${MAC_OPEN_USER:-jjantdev}@localhost"
ctl="$HOME/.ssh/mac-open-%r@%h:%p"
ssh_opts=(-p "$port" -o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o "ControlPath=$ctl" -o ControlPersist=10s)

host="${STARSHIP_HOST_ALIAS:-$(uname -n)}"

# Bare `code` means the current directory — an empty remote window is useless.
if [ "$#" -eq 0 ]; then
  set -- .
fi

for arg in "$@"; do
  case "$arg" in
    -*)
      echo "code: only file/dir paths are supported, not flags (got '$arg')" >&2
      exit 1
      ;;
  esac

  if [ ! -e "$arg" ]; then
    echo "code: no such file or directory: $arg" >&2
    exit 1
  fi

  src="$(realpath "$arg")"

  # The payload is line-framed; a newline in the path can't be represented.
  case "$src" in
    *$'\n'*)
      echo "code: refusing path containing a newline: $arg" >&2
      exit 1
      ;;
  esac

  kind="file"
  if [ -d "$src" ]; then
    kind="folder"
  fi

  printf '%s\n' "-> opening $src in VS Code on the Mac (attached to $host)..." >&2
  printf '%s\n%s\n%s\n' "$kind" "$host" "$src" | ssh "${ssh_opts[@]}" "$mac" code
done
