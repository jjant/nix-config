#!/usr/bin/env bash
# brazil-workspace-from-package — create a fresh Brazil workspace containing a
# single package under ~/workplace and print that package's source directory.
#
# Runnable from any shell and any directory (all paths are absolute). The
# matching fish function (modules/home/fish.nix) additionally cd's into the
# printed path; from other shells use: cd "$(brazil-workspace-from-package X)".

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

# Create the workspace and step into the package source. Brazil's own output is
# sent to stderr so stdout carries only the final path (for the fish wrapper /
# command substitution). On any failure, remove the partial workspace.
if {
  cd "$HOME/workplace" &&
    brazil ws create --name "$package" &&
    cd "$package" &&
    brazil ws use -p "$package" &&
    cd "src/$package"
} >&2; then
  pwd
else
  echo "Failed to set up workspace for '$package'; cleaning up" >&2
  rm -rf "$workspace_dir"
  exit 1
fi
