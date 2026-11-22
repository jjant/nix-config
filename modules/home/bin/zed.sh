#!/usr/bin/env bash
# zed — open a Cloud Desktop path in Zed on the Mac over SSH.
# Sends the kind, host and path on separate lines through the reverse tunnel.
# The Mac's forced-command receiver builds the SSH URL. Files stay on the desk.
#
# Env overrides: MAC_OPEN_PORT (default 2022), MAC_OPEN_USER (default jjantdev).
# STARSHIP_HOST_ALIAS selects the Mac's WSSH alias, with the FQDN as fallback.

set -euo pipefail

case "${1:-}" in
  -h | --help)
    printf '%s\n' \
      'Usage: zed [--] [PATH...]' \
      'Open files/directories in Zed on the Mac, attached to this desk over SSH.' \
      'With no paths, open the current directory. Other Zed flags are unsupported.'
    exit 0
    ;;
  --) shift ;;
esac

host="${STARSHIP_HOST_ALIAS:-$(uname -n)}"

if [ "$#" -eq 0 ]; then
  set -- .
fi

for arg in "$@"; do
  if [ ! -e "$arg" ]; then
    echo "zed: expected an existing file or directory: $arg" >&2
    echo "Try 'zed --help' for usage." >&2
    exit 1
  fi

  # Preserve even trailing newlines so validation cannot silently trim a path.
  IFS= read -r -d '' src < <(realpath -z -- "$arg")
  # The payload is line-framed, and the receiver rejects control characters.
  if [[ $src == *[[:cntrl:]]* ]]; then
    echo "zed: refusing path containing control characters: $arg" >&2
    exit 1
  fi

  kind="file"
  if [ -d "$src" ]; then
    kind="folder"
  fi

  printf '%s\n' "-> opening $src in Zed on the Mac (attached to $host)..." >&2
  printf '%s\n%s\n%s\n' "$kind" "$host" "$src" | mac-ssh zed
done
