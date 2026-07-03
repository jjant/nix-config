#!/usr/bin/env bash
# The fd and fzf invocations below are substituted with pinned Nix store
# paths at build time (see ../bin/default.nix); the placeholders keep this a
# real, editor-friendly shell script rather than an inline Nix string.

directories=(
  "$HOME"
  "$HOME"/work
  "$HOME"/personal
  "$HOME"/.config
  "$HOME"/workplace
)
selected=$(@fd@ -L --min-depth 1 --max-depth 1 --type d . "${directories[@]}" | @fzf@)

if [[ -z $selected ]]; then
  exit 0
fi

session_name=$(basename "$selected" | tr ".: " "_")

if ! tmux has-session -t="$session_name" 2> /dev/null; then
  tmux new-session -s "$session_name" -n "workspace" -c "$selected" -d

  parent=$(realpath "$(dirname "$selected")")

  if [[ $parent = "/Volumes/workplace" ]]; then
    for dir in "$selected/src"/*; do
      if [[ -d "$dir" ]]; then
        tmux new-window -c "$dir" -n "$(basename "$dir")" -t "$session_name"
      fi
    done
  fi
fi

if [[ -z "$TMUX" ]]; then
  tmux attach -t "$session_name"
else
  tmux switch-client -t "$session_name"
fi
