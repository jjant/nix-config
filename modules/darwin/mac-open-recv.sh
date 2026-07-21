# shellcheck shell=bash
# mac-open-recv — forced-command receiver for the dev-desk `open`/`code` flows.
#
# Pinned as the authorized_keys `command="..."` for the dev-desk key, so this is
# the ONLY thing that key can run — never an arbitrary shell. The clients
# (modules/home/bin/open.sh and code.sh) send a fixed mode token as the ssh
# command and the payload on stdin:
#   - url:  a URL on stdin; opened on the Mac (web schemes only).
#   - file: a zstd-compressed tar on stdin; extracted to a temp dir and opened.
#   - code: kind + host + path, one per line; VS Code here attaches back to
#           that host over Remote-SSH and opens the path (nothing is copied).
#
# $SSH_ORIGINAL_COMMAND is client-controlled and therefore untrusted: it is only
# ever matched against the fixed vocabulary below, never executed. Client input
# never reaches a shell; nothing here is `eval`'d.
#
# Note: `open` on macOS is a code-execution primitive (it launches .app bundles,
# .command files, URL-scheme handlers, ...). This receiver narrows that as far
# as it reasonably can — web-only URL schemes, extraction into a fresh dir with
# no client-controlled path, and a com.apple.quarantine tag so Gatekeeper vets
# anything executable — but it cannot make opening attacker-supplied content
# fully safe. That residual is inherent to the feature. `code` is kept on the
# same leash: every payload field is checked against a closed grammar and the
# vscode-remote:// URI is assembled here, never accepted pre-built — but
# attaching Remote-SSH to a payload-named host still means trusting that host.
#
# Runs under the writeShellApplication-pinned bash and as the login user (so
# `open` and `code` reach the desktop session). macOS tools are called by
# absolute path so PATH in the forced-command environment is irrelevant; `zstd`
# and `code` come from the writeShellApplication runtimeInputs (macOS's
# libarchive has no built-in zstd, and VS Code's CLI lives in the user profile,
# which sshd's bare forced-command environment doesn't have on PATH).

# Percent-encode a path for embedding in a URI: keep [A-Za-z0-9/._~-], encode
# every other byte. LC_ALL=C makes ${s:i:1} slice bytes, not characters, so
# multi-byte UTF-8 comes out as %XX%XX... sequences, which VS Code decodes.
encode_path() {
  local LC_ALL=C s="$1" out="" ch i
  for ((i = 0; i < ${#s}; i++)); do
    ch="${s:i:1}"
    case "$ch" in
      [a-zA-Z0-9/._~-]) out+="$ch" ;;
      *)
        printf -v ch '%%%02X' "'$ch"
        out+="$ch"
        ;;
    esac
  done
  printf '%s' "$out"
}

case "${SSH_ORIGINAL_COMMAND:-}" in
  url)
    url="$(cat)"
    case "$url" in
      http://* | https://*) exec /usr/bin/open -- "$url" ;;
      *)
        printf 'mac-open-recv: refused non-web URL\n' >&2
        exit 1
        ;;
    esac
    ;;
  file)
    # Isolated extraction dir chosen by us — the client never supplies a path.
    # The stream is zstd: macOS's libarchive has no built-in zstd, so decompress
    # with the pinned zstd (runtimeInputs) and pipe a plain tar into bsdtar.
    # Without -P bsdtar strips leading '/' and blocks '..' escapes; we run
    # non-root so archived ownership is not restored.
    dest="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/mac-open.XXXXXX")"
    zstd -d | /usr/bin/tar -xf - -C "$dest"

    # Tag everything so Gatekeeper engages on any executable/app that arrived.
    /usr/bin/xattr -w -r com.apple.quarantine \
      "0081;$(printf '%x' "$(/bin/date +%s)");mac-open;$(/usr/bin/uuidgen)" \
      "$dest" 2>/dev/null || true

    # Open the entry WE resolve from disk. If the archive expanded to a single
    # top-level item, open that; otherwise fall back to revealing the dir.
    first="$(/usr/bin/find "$dest" -mindepth 1 -maxdepth 1 -print -quit)"
    count="$(/usr/bin/find "$dest" -mindepth 1 -maxdepth 1 | /usr/bin/wc -l | /usr/bin/tr -d '[:space:]')"
    if [ "$count" = "1" ] && [ -n "$first" ]; then
      exec /usr/bin/open -- "$first"
    else
      exec /usr/bin/open -- "$dest"
    fi
    ;;
  code)
    # VS Code Remote-SSH launcher. Three payload lines — kind, host, path —
    # are all data, never executed: each is validated against a closed
    # grammar and the URI is assembled here, so no client-controlled string
    # is ever interpreted as a flag, command, or pre-built URI. Under the
    # injected errexit, a short read (missing lines) aborts the script.
    IFS= read -r kind
    IFS= read -r host
    IFS= read -r path

    case "$kind" in
      folder) flag="--folder-uri" ;;
      file) flag="--file-uri" ;;
      *)
        printf 'mac-open-recv: bad kind\n' >&2
        exit 1
        ;;
    esac

    # Hostname/alias charset only (covers the ssh aliases like al2-x86_64 and
    # dev-dsk FQDNs) — nothing that could smuggle in URI structure or flags.
    if ! [[ $host =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
      printf 'mac-open-recv: bad host\n' >&2
      exit 1
    fi

    # Absolute path, no control characters (read already ate the newline).
    if [[ $path != /* ]] || [[ $path == *[[:cntrl:]]* ]]; then
      printf 'mac-open-recv: bad path\n' >&2
      exit 1
    fi

    # `code` is the pinned pkgs.vscode CLI from runtimeInputs. VS Code SSHes
    # back to $host itself (via ~/.ssh config: wssh proxy + control socket).
    exec code "$flag" "vscode-remote://ssh-remote+${host}$(encode_path "$path")"
    ;;
  *)
    printf 'mac-open-recv: unknown mode\n' >&2
    exit 1
    ;;
esac
