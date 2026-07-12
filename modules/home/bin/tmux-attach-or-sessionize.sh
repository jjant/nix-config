#!/usr/bin/env bash
# tmux-attach-or-sessionize -- drop into tmux for an interactive SSH login on
# the cloud desktop: attach to the most-recently-used session, or launch
# tmux-sessionizer (the fzf project picker) when no session exists yet.
# Cancelling the picker (Esc) leaves you in a plain shell.
#
# The caller decides *when* to run this: fish's interactiveShellInit fires it
# only on interactive SSH shells that aren't already inside tmux. tmux and
# tmux-sessionizer are rewritten to absolute Nix store paths by resholve (see
# default.nix), so this never depends on PATH.
tmux attach 2>/dev/null || tmux-sessionizer
