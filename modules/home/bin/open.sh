#!/usr/bin/env bash
# open — on a Linux dev desk, hand a file, directory, or URL to the Mac's
# native `open`, printing where a copied file/dir landed on the Mac.
#
# Options:
#   -d FILE  Copy FILE's entire containing directory, then open FILE inside the
#            copy. This keeps sibling assets available for HTML reports and
#            similar artifacts. References through `..` leave that directory
#            and are therefore not included.
#   -s PATH  Share instead of open: the Mac uploads the payload to the team's
#            Amazon Drive folder and prints back a recipient link.
# `-d` and `-s` are intentionally mutually exclusive.
#
# Transport: the Mac's ssh config (modules/home/ssh.nix) sets
#   RemoteForward 2022 localhost:22
# so this host's localhost:2022 reaches the Mac's sshd, where a locked-down
# forced command (modules/darwin/mac-open-recv.sh, pinned via the authorized
# key's command="...") receives the request.
#
# Protocol: this client sends only a fixed mode token as the ssh command --
# `url`, `file`, `directory`, or `share` -- and the payload on stdin:
#   - url:       the URL text on stdin; both sides accept web URLs only.
#   - file:      a zstd-compressed tar of the file/dir on stdin (single
#                connection, few round-trips -- far faster than per-file scp
#                for trees). The Mac decompresses, extracts to a temp dir,
#                opens it, and echoes the Mac-side path of the copy back -- the
#                only stdout of the mode, so `open x` composes with pipes and
#                the path is there to paste into something else on the Mac.
#   - directory: used by `-d`; a NUL-terminated entrypoint basename followed by
#                a zstd-compressed tar of its containing directory's contents.
#                The Mac extracts the whole context but opens the named file.
#   - share:     the same stream as `file`, but the Mac zips directories,
#                uploads the artifact to Amazon Drive with its own Midway
#                session, echoes the share link back, and pops the link's page
#                in its browser. The upload happens on the Mac because Drive
#                lets laptops in on the Midway cookie alone, while corp-network
#                hosts like this one are routed to a Kerberos-only IdP.
# `pv` draws a client-side transfer progress bar so a large copy never looks
# stuck. Progress goes to stderr; returned paths/links are the only stdout.
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

usage() {
  printf '%s\n' \
    'Usage:' \
    '  open URL...' \
    '  open PATH...' \
    '  open -d FILE...' \
    '  open -s PATH...' \
    '' \
    'Open URLs and local artifacts on the Mac from a Linux dev desk.' \
    '' \
    'Options:' \
    '  -d  Copy the contents of each FILE'\''s resolved parent directory, then' \
    '      open FILE inside the copy. Use this for generated HTML with sibling' \
    '      CSS, JavaScript, images, or other relative assets.' \
    '' \
    '      Only the immediate parent is copied: references outside it, such as' \
    '      ../shared/style.css, are not included. -d accepts files only and' \
    '      cannot be combined with -s.' \
    '' \
    '  -s  Upload local files or directories to Amazon Drive instead of opening' \
    '      them, print the share link, and open that link on the Mac.' \
    '' \
    '  -h, --help' \
    '      Show this help.' \
    '' \
    'Examples:' \
    '  open https://example.com' \
    '  open result.pdf' \
    '  open output/' \
    '  open -d output/index.html' \
    '  open -s artifact.zip' \
    '' \
    'Mac-side paths and Drive links are written to stdout. Transfer progress' \
    'and diagnostics are written to stderr.'
}

share=0
with_directory=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    -d)
      with_directory=1
      shift
      ;;
    -s)
      share=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "open: unknown option: $1" >&2
      echo "Try 'open --help' for more information." >&2
      exit 1
      ;;
    *) break ;;
  esac
done

if [ "$share" -eq 1 ] && [ "$with_directory" -eq 1 ]; then
  echo "open: -d and -s cannot be used together" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 1
fi

for arg in "$@"; do
  # Only explicit web URLs go over the tunnel. Reject typos, bare domains, and
  # unsupported schemes here so they fail immediately instead of waiting for
  # the Mac-side receiver to make the same decision.
  if [ ! -e "$arg" ]; then
    if [ "$with_directory" -eq 1 ]; then
      echo "open: -d requires a local file; not found: $arg" >&2
      exit 1
    fi
    if [ "$share" -eq 1 ]; then
      echo "open: -s shares local files/dirs; not found: $arg" >&2
      exit 1
    fi
    case "$arg" in
      http://* | https://*)
        printf '%s' "$arg" | ssh "${ssh_opts[@]}" "$mac" url
        continue
        ;;
      *)
        echo "open: not a local path or explicit web URL: $arg" >&2
        exit 1
        ;;
    esac
  fi

  src="$(realpath "$arg")"
  base="$(basename "$src")"
  parent="$(dirname "$src")"

  if [ "$share" -eq 1 ]; then
    bytes="$(du -sb "$src" | cut -f1)"
    mode="share"
    printf '%s\n' "-> sharing $base ($(numfmt --to=iec "$bytes")) via the Mac to Drive..." >&2
  elif [ "$with_directory" -eq 1 ]; then
    if [ ! -f "$src" ]; then
      echo "open: -d requires a file, not a directory: $arg" >&2
      exit 1
    fi
    bytes="$(du -sb "$parent" | cut -f1)"
    mode="directory"
    printf '%s\n' \
      "-> copying $(basename "$parent")/ ($(numfmt --to=iec "$bytes")) to the Mac and opening $base..." >&2
  else
    bytes="$(du -sb "$src" | cut -f1)"
    mode="file"
    printf '%s\n' "-> copying $base ($(numfmt --to=iec "$bytes")) to the Mac..." >&2
  fi

  # Stream the payload as one zstd-compressed tar over a single SSH connection.
  # zstd is fast and stores already-compressed data efficiently. `directory`
  # prepends the basename to open, NUL-delimited so every legal filename except
  # NUL itself remains representable, then archives all sibling assets.
  # shellcheck disable=SC2029 # $mode is our own fixed token, never user input.
  if [ "$mode" = "directory" ]; then
    {
      printf '%s\0' "$base"
      tar cf - -C "$parent" -- . | pv -btr | zstd
    } | ssh "${ssh_opts[@]}" "$mac" "$mode"
  else
    tar cf - -C "$parent" -- "$base" | pv -btr | zstd | ssh "${ssh_opts[@]}" "$mac" "$mode"
  fi
done
