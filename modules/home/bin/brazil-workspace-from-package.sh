#!/usr/bin/env bash
# brazil-workspace-from-package — create a fresh Brazil workspace containing a
# single package under ~/workplace and open a tmux session for it (via
# tmux-sessionizer). Runnable from any shell; ~/workplace must already exist.

set -euo pipefail

package="${1:-}"
if [ -z "$package" ]; then
  echo "usage: brazil-workspace-from-package <package>" >&2
  exit 1
fi

workspace_dir="$HOME/workplace/$package"

# ~/workplace must already exist — do not create it; fail if it is missing.
if [ ! -d "$HOME/workplace" ]; then
  echo "Workspace root does not exist: $HOME/workplace" >&2
  exit 1
fi

# Refuse to touch a pre-existing directory so the cleanup below can never delete
# something we did not create.
if [ -e "$workspace_dir" ]; then
  echo "Workspace directory already exists: $workspace_dir" >&2
  exit 1
fi

# Create the workspace, then open a tmux session for the package source. Brazil
# output goes to stderr. On any failure, remove the partial workspace.
if {
  cd "$HOME/workplace" &&
    brazil ws create --name "$package" &&
    cd "$package" &&
    brazil ws use -p "$package"
} >&2; then
  tmux-sessionizer "$workspace_dir/src/$package"
else
  echo "Failed to set up workspace for '$package'; cleaning up" >&2
  rm -rf "$workspace_dir"
  exit 1
fi
