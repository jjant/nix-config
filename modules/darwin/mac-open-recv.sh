# shellcheck shell=bash
# mac-open-recv — forced-command receiver for the dev-desk `open`/`code` flows.
#
# Pinned as the authorized_keys `command="..."` for the dev-desk key, so this is
# the ONLY thing that key can run — never an arbitrary shell. The clients
# (modules/home/bin/open.sh and code.sh) send a fixed mode token as the ssh
# command and the payload on stdin:
#   - url:   a URL on stdin; opened on the Mac (web schemes only).
#   - file:  a zstd-compressed tar on stdin; extracted to a temp dir and opened.
#   - share: a zstd-compressed tar on stdin; extracted, zipped if it's a
#            directory, uploaded to a fixed Amazon Drive folder with this
#            user's Midway session, and the recipient link echoed on stdout
#            (which rides the ssh channel back to the dev desk).
#   - code:  kind + host + path, one per line; VS Code here attaches back to
#            that host over Remote-SSH and opens the path (nothing is copied).
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
# `share` is the tamest mode: nothing is launched — the payload is re-packed
# and uploaded to a Drive folder fixed in this script (the client cannot pick
# the destination, a path, or a URL), and its only output is the link.
#
# Runs under the writeShellApplication-pinned bash and as the login user (so
# `open` and `code` reach the desktop session, and `share` finds this user's
# ~/.midway/cookie). macOS tools are called by absolute path so PATH in the
# forced-command environment is irrelevant; `zstd`, `jq`, and `code` come from
# the writeShellApplication runtimeInputs (macOS's libarchive has no built-in
# zstd, macOS ships no jq, and VS Code's CLI lives in the user profile, which
# sshd's bare forced-command environment doesn't have on PATH).

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

# curl for drive.corp.amazon.com carrying the share-mode session jar ($jar is
# set by the `share` arm before first use). -sS: quiet, but say why on failure;
# --max-time bounds the small API calls (the S3 upload doesn't go through
# here). macOS ships curl at /usr/bin.
drive_curl() {
  /usr/bin/curl -sS --max-time 60 -b "$jar" -c "$jar" "$@"
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
  share)
    # Share the payload via Amazon Drive instead of opening it. Same transport
    # as `file` (zstd tar on stdin, extraction dir chosen by us), but nothing
    # is ever launched: the payload is re-packed if needed and uploaded to the
    # fixed folder below with the login user's Midway session; the only stdout
    # is the recipient link, riding the ssh channel back to the dev desk.
    # Upload protocol (session priming, CSRF, batch_create → S3 → complete):
    # https://w.amazon.com/bin/view/IHMPublic/Auth/llm-wiki/Drive-Corp-Programmatic-Access/
    #
    # Why the upload runs here and not on the dev desk: Federate routes
    # corp-network hosts to its Kerberos IdP (needs a TGT), while laptops ride
    # the AEA gateway, where the Midway cookie alone suffices.
    drive_base='https://drive.corp.amazon.com'
    drive_folder='folders/ACS-Artemis' # destination — fixed here, never client-chosen

    workdir="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/mac-share.XXXXXX")"
    trap '/bin/rm -rf "$workdir"' EXIT

    midway_cookie="$HOME/.midway/cookie"
    if [ ! -f "$midway_cookie" ]; then
      printf 'mac-open-recv: %s not found — run mwinit -o on the Mac\n' "$midway_cookie" >&2
      exit 1
    fi

    # Extract like `file` does: fresh dir, no client-controlled path, bsdtar
    # blocks '..' escapes without -P, zstd from runtimeInputs.
    dest="$workdir/payload"
    /bin/mkdir "$dest"
    zstd -d | /usr/bin/tar -xf - -C "$dest"

    first="$(/usr/bin/find "$dest" -mindepth 1 -maxdepth 1 -print -quit)"
    count="$(/usr/bin/find "$dest" -mindepth 1 -maxdepth 1 | /usr/bin/wc -l | /usr/bin/tr -d '[:space:]')"
    if [ -z "$first" ]; then
      printf 'mac-open-recv: empty share payload\n' >&2
      exit 1
    fi

    # Ship exactly one artifact. Directories (or a multi-entry payload, which
    # today's client never sends) become a zip so a recipient on a random corp
    # machine gets one click-to-open file — a .tar.zst would be hostile.
    if [ "$count" = "1" ] && [ -f "$first" ]; then
      upload="$first"
    elif [ "$count" = "1" ]; then
      upload="$workdir/$(/usr/bin/basename "$first").zip"
      /usr/bin/ditto -c -k --keepParent "$first" "$upload"
    else
      upload="$workdir/share.zip"
      /usr/bin/ditto -c -k "$dest" "$upload"
    fi

    # Immutable naming: re-uploading an existing filename creates a new
    # *version* of that file in Drive — silently swapping content behind
    # already-shared links — so a UTC timestamp prefix gives every share its
    # own object. The basename is payload-derived (untrusted): collapse
    # anything outside a safe charset so it embeds cleanly in JSON, multipart
    # form fields, curl's -F @path parsing, and the echoed URL.
    safe_name="$(/usr/bin/basename "$upload")"
    safe_name="${safe_name//[^A-Za-z0-9._-]/_}"
    name="$(/bin/date -u +%Y%m%d-%H%M%S)-$safe_name"

    # Prime a Drive session into a private jar: the raw Midway cookie only
    # clears GETs; writes need the amzn_sso_*/Rails session cookies deposited
    # by walking the Federate bounce (--location-trusted re-sends cookies
    # across the redirect hosts — that's the point). Then read the CSRF token
    # and the folder's upload id (data-path) from the folder page. Order
    # matters: the CSRF token is bound to the session, so it must come from a
    # page fetched with the *primed* jar.
    jar="$workdir/jar"
    /bin/cp "$midway_cookie" "$jar"
    /bin/chmod 600 "$jar"
    drive_curl --location-trusted -o /dev/null "$drive_base/"

    page="$workdir/folder.html"
    drive_curl --location-trusted -o "$page" "$drive_base/$drive_folder"
    csrf="$(/usr/bin/sed -nE 's/.*<meta name="csrf-token" content="([^"]+)".*/\1/p' "$page" | /usr/bin/head -n 1)"
    data_path="$(/usr/bin/sed -nE "s/.*id=[\"']upload[\"'][^>]*data-path=[\"']([^\"']+)[\"'].*/\1/p" "$page" | /usr/bin/head -n 1)"
    if [ -z "$data_path" ]; then # attribute order isn't guaranteed; try reversed
      data_path="$(/usr/bin/sed -nE "s/.*data-path=[\"']([^\"']+)[\"'][^>]*id=[\"']upload[\"'].*/\1/p" "$page" | /usr/bin/head -n 1)"
    fi
    if [ -z "$csrf" ] || [ -z "$data_path" ]; then
      printf 'mac-open-recv: no Drive session (stale Midway cookie? run mwinit -o on the Mac) or no upload access to %s/%s\n' \
        "$drive_base" "$drive_folder" >&2
      exit 1
    fi

    printf 'mac-open-recv: uploading %s to Drive (%s)\n' "$name" "$data_path" >&2

    # 1/3: register the filename with Drive → presigned S3 POST target.
    resp="$workdir/batch_create.json"
    jq -cn --arg id "$data_path" --arg name "$name" '{id: $id, paths: [$name]}' |
      drive_curl -o "$resp" \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        -H "X-CSRF-Token: $csrf" -H 'X-Requested-With: XMLHttpRequest' \
        --data-binary @- "$drive_base/uploads/batch_create"
    if ! s3_url="$(jq -er --arg n "$name" '.[$n].url' "$resp")"; then
      printf 'mac-open-recv: batch_create failed: %s\n' "$(/bin/cat "$resp")" >&2
      exit 1
    fi
    s3_key="$(jq -er --arg n "$name" '.[$n].fields.key' "$resp")"

    # 2/3: multipart POST to S3 — every presigned field, the file strictly
    # last, and no Drive cookies (different host). --form-string keeps field
    # values literal where -F would interpret @, <, and ;type=. The file is
    # hardlinked to its sanitized name so the -F @path stays metacharacter-free.
    form_args=()
    while IFS=$'\t' read -r k v; do
      form_args+=(--form-string "$k=$v")
    done < <(jq -r --arg n "$name" '.[$n].fields | to_entries[] | [.key, .value] | @tsv' "$resp")
    staged="$workdir/$name"
    /bin/ln "$upload" "$staged"
    status="$(/usr/bin/curl -sS -o "$workdir/s3.out" -w '%{http_code}' \
      -X POST "$s3_url" "${form_args[@]}" -F "file=@$staged")"
    case "$status" in
      200 | 201 | 204) ;;
      *)
        printf 'mac-open-recv: S3 upload failed (HTTP %s): %s\n' "$status" "$(/bin/cat "$workdir/s3.out")" >&2
        exit 1
        ;;
    esac

    # 3/3: commit — Drive only lists the file after /uploads/complete.
    completed="$(jq -cn --arg k "$s3_key" '{keys: [$k]}' |
      drive_curl \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        -H "X-CSRF-Token: $csrf" -H 'X-Requested-With: XMLHttpRequest' \
        --data-binary @- "$drive_base/uploads/complete")"
    if ! printf '%s' "$completed" | jq -e '(.success | length > 0) and (.fail | length == 0)' >/dev/null; then
      printf 'mac-open-recv: uploads/complete failed: %s\n' "$completed" >&2
      exit 1
    fi

    # The mode's only stdout: the recipient link (direct download). data_path
    # is server-provided and name is sanitized above — both embed in a URL
    # as-is.
    printf '%s/view/%s/%s?download=true\n' "$drive_base" "$data_path" "$name"
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
