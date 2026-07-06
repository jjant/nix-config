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

# Build the window layout for a directory: one window per child repo (or Brazil
# src/ package) as appropriate. The session and its "workspace" window must
# already exist.
populate_windows() {
  local session=$1 selected=$2 parent
  parent=$(realpath "$(dirname "$selected")")
  if is_brazil_workspace "$parent"; then
    # Brazil workspace: one window per package under src/.
    open_child_windows "$session" "$selected/src" all
  elif [[ ! -e $selected/.git ]]; then
    # A directory that isn't itself a git repo may be a container of repos
    # (e.g. ~/personal/snowpark holding docs/, landing/, ...). Open one window
    # per child repo, but only when there are few enough of them.
    open_child_windows "$session" "$selected" git "$max_repo_windows"
  fi
}

# Rebuild the current tmux session's windows to the layout tmux-sessionizer
# originally created, discarding any windows opened or directories navigated to
# since. Uses the @sessionizer_root option saved at creation time.
#
# This runs inside one of the session's own panes, so it must not destroy its
# own window before finishing. It builds the fresh layout first, then removes
# every previously-existing window (including this one) and renumbers in a
# single batched tmux command: the tmux server runs the whole batch even though
# killing our window terminates this script partway through it.
reset_session() {
  local session root wsid id
  local old_ids=() args=()
  session=$(tmux display-message -p '#S')
  root=$(tmux show-options -t "$session" -qv @sessionizer_root)
  if [[ -z $root ]]; then
    tmux display-message "tmux-sessionizer: no saved root for this session — nothing to reset"
    return
  fi
  # Windows to remove afterwards (captured before we add the fresh ones).
  readarray -t old_ids < <(tmux list-windows -t "$session" -F '#{window_id}')
  wsid=$(tmux new-window -P -F '#{window_id}' -t "$session" -n workspace -c "$root")
  populate_windows "$session" "$root"
  tmux select-window -t "$wsid"
  for id in "${old_ids[@]}"; do
    args+=(kill-window -t "$id" ";")
  done
  args+=(move-window -r -t "$session")
  tmux "${args[@]}"
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

# "reset this session" is offered as the LAST entry (and only inside tmux, where
# there is a current session to reset) so it is never the default selection —
# you must deliberately move to it. It's coloured red to stand out; fzf --ansi
# renders the colour and returns the entry's plain text, which we match below.
reset_entry="↺  reset this session"
selected=$(
  {
    fd -L --min-depth 1 --max-depth 1 --type d . "${directories[@]}"
    [[ -n $TMUX ]] && printf '\033[1;38;2;255;85;85m%s\033[0m\n' "$reset_entry"
  } | fzf --ansi
)

if [[ -z $selected ]]; then
  exit 0
fi

if [[ $selected == "$reset_entry" ]]; then
  # Reset rebuilds the session (drops stray windows and resets directories), so
  # confirm first. fzf highlights the first line by default, so Enter or Escape
  # cancels — you have to pick "reset" deliberately.
  confirm=$(printf 'cancel\nreset this session\n' | fzf --prompt='reset this session? ')
  if [[ $confirm == "reset this session" ]]; then
    reset_session
  fi
  exit 0
fi

session_name=$(basename "$selected" | tr ".: " "_")

if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -s "$session_name" -n "workspace" -c "$selected" -d
  # Remember the directory this session was built from so "reset this session"
  # can rebuild the same layout later.
  tmux set-option -t "$session_name" @sessionizer_root "$selected"
  populate_windows "$session_name" "$selected"
fi

if [[ -z $TMUX ]]; then
  tmux attach -t "$session_name"
else
  tmux switch-client -t "$session_name"
fi
