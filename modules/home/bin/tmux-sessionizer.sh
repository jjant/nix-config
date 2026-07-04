#!/usr/bin/env bash
# External commands (fd, fzf, tmux, coreutils) are resolved to absolute Nix
# store paths at build time by resholve (see ../bin/default.nix), so this
# stays a normal, editor-friendly shell script.

# When a selected directory isn't itself a git repo but contains child repos,
# open one tmux window per repo — unless there are more than this many, in which
# case just open a single "workspace" window so a directory full of repos
# doesn't spawn a wall of windows.
max_repo_windows=6

# Open one tmux window per child repo of $scan_dir in $session. A child repo is
# an immediate subdirectory; when $require_git is "git" only subdirectories that
# are themselves git repos count, otherwise every subdirectory does (used for
# Brazil `src/` packages). When $max > 0 and there are more repos than that,
# open nothing (leaving just the single "workspace" window).
open_child_windows() {
  local session=$1 scan_dir=$2 require_git=$3 max=${4:-0}
  local repos=() dir
  for dir in "$scan_dir"/*; do
    [[ -d $dir ]] || continue
    if [[ $require_git == git && ! -e $dir/.git ]]; then
      continue
    fi
    repos+=("$dir")
  done

  local count=${#repos[@]}
  if ((count == 0)); then
    return
  fi
  if ((max > 0)) && ((count > max)); then
    return
  fi

  for dir in "${repos[@]}"; do
    tmux new-window -c "$dir" -n "$(basename "$dir")" -t "$session"
  done
}

# Brazil workspaces live under /Volumes/workplace on macOS (reached via the
# ~/workplace symlink, which realpath resolves) and directly under ~/workplace
# on the Linux cloud desktops. A selected workspace's realpath'd parent matches
# one of these roots.
is_brazil_workspace() {
  local parent=$1 root
  for root in "/Volumes/workplace" "$HOME/workplace"; do
    [[ -d $root ]] || continue
    [[ $parent == "$(realpath "$root")" ]] && return 0
  done
  return 1
}

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

  if is_brazil_workspace "$parent"; then
    # Brazil workspace: one window per package under src/.
    open_child_windows "$session_name" "$selected/src" all
  elif [[ ! -e $selected/.git ]]; then
    # A directory that isn't itself a git repo may be a container of repos
    # (e.g. ~/personal/snowpark holding docs/, landing/, ...). Open one window
    # per child repo, but only when there are few enough of them.
    open_child_windows "$session_name" "$selected" git "$max_repo_windows"
  fi
fi

if [[ -z $TMUX ]]; then
  tmux attach -t "$session_name"
else
  tmux switch-client -t "$session_name"
fi
