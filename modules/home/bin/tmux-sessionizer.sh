#!/usr/bin/env bash
# External commands (fd, fzf, tmux, coreutils) are resolved to absolute Nix
# store paths at build time by resholve (see ../bin/default.nix), so this
# stays a normal, editor-friendly shell script.

candidates=(
  "$HOME"
  "$HOME"/work
  "$HOME"/personal
  "$HOME"/.config
  "$HOME"/workplace
)

# Only search directories that actually exist. Otherwise fd prints
# "[fd error]: Search path '...' is not a directory" for each missing one
# (and exits non-zero if they're all missing). Which of these exist varies
# per host, e.g. ~/workplace only exists on the Amazon dev desktops.
directories=()
for dir in "${candidates[@]}"; do
  [[ -d $dir ]] && directories+=("$dir")
done

if [[ ${#directories[@]} -eq 0 ]]; then
  echo "tmux-sessionizer: none of the candidate directories exist" >&2
  exit 1
fi

selected=$(fd -L --min-depth 1 --max-depth 1 --type d . "${directories[@]}" | fzf)

if [[ -z $selected ]]; then
  exit 0
fi

session_name=$(basename "$selected" | tr ".: " "_")

if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -s "$session_name" -n "workspace" -c "$selected" -d

  parent=$(realpath "$(dirname "$selected")")

  if [[ $parent == "/Volumes/workplace" ]]; then
    for dir in "$selected/src"/*; do
      if [[ -d $dir ]]; then
        tmux new-window -c "$dir" -n "$(basename "$dir")" -t "$session_name"
      fi
    done
  fi
fi

if [[ -z $TMUX ]]; then
  tmux attach -t "$session_name"
else
  tmux switch-client -t "$session_name"
fi
