# shellcheck shell=bash
# mac-open-recv — forced-command receiver for the dev-desk `open` flow.
#
# Pinned as the authorized_keys `command="..."` for the dev-desk key, so this is
# the ONLY thing that key can run — never an arbitrary shell. The client
# (modules/home/bin/open.sh) sends a fixed mode token as the ssh command and the
# payload on stdin:
#   - url:  a URL on stdin; opened on the Mac (web schemes only).
#   - file: a zstd-compressed tar on stdin; extracted to a temp dir and opened.
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
# fully safe. That residual is inherent to the feature.
#
# Runs under the writeShellApplication-pinned bash and as the login user (so
# `open` reaches the desktop session). macOS tools are called by absolute path
# so PATH in the forced-command environment is irrelevant; `zstd` comes from the
# writeShellApplication runtimeInputs (macOS's libarchive has no built-in zstd).

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
  *)
    printf 'mac-open-recv: unknown mode\n' >&2
    exit 1
    ;;
esac
