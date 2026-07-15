#!/usr/bin/env bash
# xdg-open — compatibility shim for the Linux dev desks (installed on Linux
# only — see default.nix).
#
# These hosts are headless: no desktop environment, and no real xdg-open
# installed. But anything that wants to open a file or URL by convention —
# coding agents, gh, `cargo doc --open`, ... — reaches for `xdg-open` and
# fails with "command not found". Hand the request to our reverse-tunnel
# `open` (open.sh) instead, which ships it to the Mac.
#
# Real xdg-open takes a single file-or-URL argument; `open` accepts that and
# more (multiple args, directories), so pass-through is a strict superset.

exec open "$@"
